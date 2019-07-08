package hxdbg;
import vscode.*;

typedef HxDebugConfig =
{
  >DebugConfiguration,
  hx_nativeLevel:Float,
  hx_debuggerPath:Null<Array<String>>,
  hx_classPath:Null<Array<String>>,
  hx_haxeExecutable:Null<vshaxe.HaxeExecutableConfiguration>,
  hx_haxeConfiguration:Null<Array<String>>,
}
