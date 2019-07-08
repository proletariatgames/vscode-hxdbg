package ;
import hxdbg.HxDebugConfig;
import hxdbg.Log;
import hxdbg.WrappedCommand;
import js.Node;
import protocol.debug.Types;
using StringTools;

class HxDebug extends hxdbg.ProtocolHandler
{
  public final wrapped:hxdbg.WrappedCommand;
  public var config(default, null):Null<HxDebugConfig>;

  function disconnectRequest(req:Request<DisconnectArguments>)
  {
    this.wrapped.sendRequest('disconnect', req.arguments, (resp:InitializeResponse) -> {
      sendResponse(req, resp);
    });
  }

  function launchOrAttachRequest(req:Request<HxDebugConfig>)
  {
    this.wrapped.sendRequest(req.command, req.arguments, (resp:Response<{}>) -> {
      sendResponse(req, resp);
    });
  }

  function initializeRequest(req:Request<InitializeRequestArguments>)
  {
    if (req.arguments.adapterID.startsWith('hx'))
    {
      req.arguments.adapterID = req.arguments.adapterID.substr(2);
    } else {
      this.sendErrorResponse(cast response, 'Invalid debugger adapter ${req.arguments.adapterID}');
      return;
    }
    this.wrapped.sendRequest('initialize', req.arguments, (resp:InitializeResponse) -> {
      if (resp.body.exceptionBreakpointFilters != null)
      {
        resp.body.exceptionBreakpointFilters.push({ filter: 'hxall', label: 'All Haxe Exceptions' });
        resp.body.exceptionBreakpointFilters.push({ filter: 'hxnullref', label: 'Haxe Null Reference' });
      }
      resp.body.supportsCompletionsRequest = true;
      sendResponseTo(req, resp.body);
    });
  }

  function setBreakpoints(req:SetBreakpointsRequest)
  {
    if (req.arguments.source.path != null && req.arguments.source.path.toLowerCase().endsWith('.hx'))
    {
      Log.warn('// TODO haxe breakpoints');
      this.sendErrorResponse(req, 'Haxe breakpoints are still not implementd');
    } else {
      this.wrapped.sendRequest(req.command, req.arguments, (resp:SetBreakpointsResponse) -> {
        sendResponse(req, resp);
      });
    }
  }

  public function new()
  {
    this.start(Node.process.stdin, Node.process.stdout);
    js.Node.process.on('uncaughtException', function(err, origin) {
      Log.err('Uncaught exception: $err\nOrigin: $origin');
      Log.end(() -> js.Node.process.exit(1));
    });

    Log.init();
    #if debug
    Log.initLogFile('C:/tmp/dbg.log');
    #end

    trace(Sys.args());
    this.wrapped = new hxdbg.WrappedCommand(Sys.args().copy());
    this.wrapped.process.on(WrappedEvent.Error, (err:js.lib.Error) -> {
      Log.err('error on wrapped $err');
      sendEvent(new adapter.DebugSession.OutputEvent('Error while opening the wrapped process: $err', stderr));
      this.stop();
    });
    this.wrapped.process.on(WrappedEvent.Exit, (code:Int, sig:String) -> {
      trace('exit $code');
      Log.end(() -> js.Node.process.exit(code));
    });
    this.wrapped.onRequest = onWrappedRequest;
    this.wrapped.onEvent = onWrappedEvent;
  }

  override function onRequest<T>(request:Request<T>) {
    switch(request.command)
    {
      case 'initialize':
        this.initializeRequest(cast request);
      case 'disconnect':
        this.disconnectRequest(cast request);
      case 'launch' | 'attach':
        this.launchOrAttachRequest(cast request);
      case 'setBreakpoints':
        this.setBreakpoints(cast request);
      case 'configurationDone' | 'threads':
        this.wrapped.sendRequest(request.command, request.arguments, (resp:Response<Dynamic>) -> {
          this.sendResponse(request, resp);
        });
      case _:
        trace('Unknown request $request');
    }
  }

  function onWrappedRequest<T>(request:protocol.debug.Types.Request<T>):Void
  {
    switch(request.command)
    {
      case 'handshake':
        this.sendRequest(request.command, request.arguments, (resp) ->
          this.wrapped.sendResponse(request, resp)
        );
      case _:
        trace('Unknown wrapped request $request');
    }
  }

  function onWrappedEvent<T>(event:protocol.debug.Types.Event<T>):Void
  {
    switch(event.event)
    {
      // passthrough events
      case 'output' | 'initialized' | 'module' | 'thread' | 'process' | 'terminated' | 'exited':
        this.sendEvent(event);
      case _:
        trace('Unknown event $event');
    }
  }

  public function stop()
  {
    js.Node.process.exit();
  }

  public static final instance:HxDebug = new HxDebug();

  static function main()
  {
    js.Node.process.stderr.write('here1\n');
  }
}