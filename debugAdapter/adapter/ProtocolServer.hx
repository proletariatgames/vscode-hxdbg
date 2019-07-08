package adapter;

// import js.
import protocol.debug.Types;

extern class ProtocolServer {
  function new();
	function sendEvent<T>(event:Event<T>):Void;
	function sendResponse<T>(response:Response<T>):Void;
  function sendRequest<Req,Res>(command:String, args:Req, timeout:Float, cb:Response<Res>->Void):Void;
  function start(inStream:js.node.stream.Readable.IReadable, outStream:js.node.stream.Writable.IWritable):Void;
  function stop():Void;
  private function dispatchRequest<T>(request:protocol.debug.Types.Request<T>):Void;
}