package hxdbg;

import haxe.extern.EitherType;
import protocol.debug.Types;
import js.node.Buffer;
import js.node.stream.Writable.IWritable;
import js.node.stream.Readable.ReadableEvent;
import js.node.stream.Readable.IReadable;
using StringTools;

class ProtocolHandler
{
  private var rawData:String = '';
  private var contentLength:Null<Int>;

  private var seq:Int = 0;
  private final callbacks:Map<Int, Response<Dynamic>->Void> = new Map();
  static final TWO_CRLF = '\r\n\r\n';
  private var output:IWritable;
  private var input:IReadable;

  private function start(input:IReadable, output:IWritable)
  {
    input.on(ReadableEvent.Data, onData);
    this.input = input;
    this.output = output;
  }

  public dynamic function onRequest<T>(request:protocol.debug.Types.Request<T>):Void
  {
    trace(request);
  }

  public dynamic function onEvent<T>(event:protocol.debug.Types.Event<T>):Void
  {
    trace(event);
  }

  public function sendRequest<Req,Res>(command:String, args:Req, cb:protocol.debug.Types.Response<Res>->Void):Void
  {
    this.callbacks[seq] = cast cb;
    var msg:Request<Req> = {
      seq: seq++,
      type: 'request',
      command: command,
      arguments: args
    };
    this.send(msg, false);
  }

  public function sendEvent<T>(event:protocol.debug.Types.Event<T>)
  {
    this.send(event);
  }

  function sendResponseTo<Req, Res>(req:Request<Req>, res:Res)
  {
    final response:Response<Res> = {
      request_seq: req.seq,
      seq:0,
      type:response,
      success:true,
      command:req.command,
      body:res
    };
    this.send(response);
  }

  function sendResponse<Req, Res>(req:Request<Req>, res:Response<Res>)
  {
    res.request_seq = req.seq;
    this.send(res);
  }

  function sendErrorResponse<Req>(req:Request<Req>, message:String)
  {
    final response:Response<Dynamic> = {
      request_seq: req.seq,
      seq:0,
      type:response,
      success:false,
      command:req.command,
      message:message
    };
    this.send(response);
  }

  function send(msg:ProtocolMessage, setSeq=true)
  {
    if (setSeq)
    {
      msg.seq = seq++;
    }

    var verb = msg.type == 'event' ? LogVerbosity.VeryVerbose : LogVerbosity.Verbose;
    if (verb >= Log.verbosity)
    {
      trace(verb, '\n${this}: -> ${untyped msg.command} $msg');
    }
    var json = haxe.Json.stringify(msg);
    output.write('Content-Length: ${json.length}$TWO_CRLF');
    output.write(json);
  }

  function onData(data:EitherType<Buffer, String>)
  {
    this.rawData += Std.is(data, Buffer) ? (data : Buffer).toString('utf8') : data;
    while (rawData.length > 0)
    {
      if (contentLength == null)
      {
        var idx = rawData.indexOf(TWO_CRLF);
        if (idx >= 0)
        {
          var headers = rawData.substr(0, idx);
          for (header in headers.split('\r\n'))
          {
            var pair = header.split(': ');
            if (pair[0].toLowerCase() == 'content-length')
            {
              this.contentLength = Std.parseInt(pair[1]);
            }
          }
          if (this.contentLength == null)
          {
            Log.err('Message without content-length');
            trace(rawData);
            throw 'assert';
          }
          rawData = rawData.substr(idx + 4);
        } else {
          break; // no header yet
        }
      } else if(rawData.length >= contentLength) {
        var msg = rawData.substr(0, contentLength);
        rawData = rawData.substr(contentLength);
        contentLength = null;
        var json:Dynamic = haxe.Json.parse(msg);
        var verb = json.type == 'event' ? LogVerbosity.VeryVerbose : LogVerbosity.Verbose;
        if (verb >= Log.verbosity)
        {
          trace(verb, '\n${this}: <- $json');
        }
        if (json.type == 'request')
        {
          this.onRequest(json);
        } else if (json.type == 'event') {
          this.onEvent(json);
        } else if (json.type == 'response') {
          var cb = this.callbacks[json.request_seq];
          if (cb != null)
          {
            cb(json);
            this.callbacks.remove(json.request_seq);
          } else {
            Log.warn('No callback for response $json');
          }
        }
      } else {
        break; // need more data
      }
    }
  }

  public function toString()
  {
    return Type.getClassName(Type.getClass(this));
  }
}