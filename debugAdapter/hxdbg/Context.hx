package hxdbg;

import haxe.Constraints.Function;
import js.node.events.EventEmitter;

@:enum abstract ContextEvent<T:Function>(Event<T>) to Event<T> {
	var ConfigSet : ContextEvent<HxDebugConfig->Void> = "configSet";
}

class Context extends EventEmitter<Context>
{
  public final sources:Sources;
  public final breakpoints:Breakpoints;
  public final wrapped:hxdbg.WrappedCommand;
  public var config(default, null):Null<HxDebugConfig>;

  public function new(wrapped)
  {
    super();
    this.wrapped = wrapped;
    this.breakpoints = new Breakpoints(this);
    this.sources = new Sources(this);
  }

  public function setConfig(config:HxDebugConfig)
  {
    if (this.config != null)
    {
      Log.fail('Config was already set');
    }
    if (config == null)
    {
      Log.fail('Config was null');
    }
    this.config = config;
    this.emit(ConfigSet, config);
  }
}