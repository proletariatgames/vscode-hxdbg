package hxdbg;
import haxe.Constraints.Function;
import js.node.ChildProcess;

typedef WrappedEvent<T:Function> = js.node.child_process.ChildProcess.ChildProcessEvent<T>;

class WrappedCommand extends ProtocolHandler
{
  public final process:js.node.child_process.ChildProcess;

  public function new(args:Array<String>)
  {
    this.process = js.node.ChildProcess.spawn(args.shift(), args, {stdio:['pipe','pipe',js.Node.process.stderr]});
    this.start(this.process.stdout, this.process.stdin);
  }

  override function toString():String {
    return 'Wrapped';
  }
}