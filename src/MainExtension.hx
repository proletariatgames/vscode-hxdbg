import hxdbg.HxDebugConfig;
import js.lib.Promise;
import vscode.*;
import Vshaxe;

using StringTools;
using Lambda;

class Main
{
  static final debuggers = ['cppvsdbg', 'cppdbg'];

  @:expose("activate")
  public static function activate(context:vscode.ExtensionContext)
  {
    for (dbg in debuggers)
    {
      context.subscriptions.push(Vscode.debug.registerDebugConfigurationProvider('hx$dbg', cast new DebugConfigProvider(context,dbg)));
      context.subscriptions.push(Vscode.debug.registerDebugAdapterDescriptorFactory('hx$dbg', new DebugConfigProvider(context, dbg)));
    }
  }
}

class DebugConfigProvider
{
  final dbg:String;
  final context:ExtensionContext;
  public function new(context, dbg)
  {
    this.dbg = dbg;
    this.context = context;
  }

	public function createDebugAdapterDescriptor(session:DebugSession, ?executable:DebugAdapterExecutable):ProviderResult<DebugAdapterDescriptor>
  {
    trace('here2');
    for (arg in (cast session.configuration : HxDebugConfig).hx_debuggerPath)
    {
      executable.args.push(arg);
    }
    return executable;
  }

  public function resolveDebugConfiguration(folder:Null<WorkspaceFolder>, debugConfiguration:HxDebugConfig,
    ?token:CancellationToken):ProviderResult<DebugConfiguration>
  {
    trace('here');
    // handle hx_debuggerPath
    if (debugConfiguration.hx_debuggerPath == null)
    {
      final path = Vscode.workspace.getConfiguration('hxdbg').get(this.dbg + '.debuggerPath');
      if (path != null)
      {
        debugConfiguration.hx_debuggerPath = path;
      }

      if (debugConfiguration.hx_debuggerPath == null)
      {
        final ext = Vscode.extensions.getExtension('ms-vscode.cpptools');
        if (ext == null)
        {
          Vscode.window.showErrorMessage('Cannot start debugger: The cpptools extension was not found!');
          return Promise.reject('cpptools was not found');
        }

        var path = null;
        final args = [];
        switch(this.dbg)
        {
        case 'cppdbg':
          if (js.node.Os.platform() == 'win32')
          {
            path = 'debugAdapters/bin/OpenDebugAD7.exe';
          } else {
            path = 'debugAdapters/OpenDebugAD7';
          }
        case 'cppvsdbg':
          path = "debugAdapters/vsdbg/bin/vsdbg.exe";
          args.push('--interpreter=vscode');
        case _:
          Vscode.window.showErrorMessage('Cannot start debugger: Unknown debugger type $dbg');
          return Promise.reject('assert');
        }
        path = ext.extensionPath + '/$path';
        if (!sys.FileSystem.exists(path))
        {
          Vscode.window.showErrorMessage('Cannot start debugger: The debugger at "$path" was not found! Please make sure that the cpptools extension is initialized and report a bug if it is!');
          return Promise.reject('Debugger was not found');
        }
        args.unshift(path);
        debugConfiguration.hx_debuggerPath = args;
      }
    }
    if (debugConfiguration.hx_debuggerPath.exists((s) -> s.contains("${cpptools}")))
    {
      final ext = Vscode.extensions.getExtension('ms-vscode.cpptools');
      if (ext == null)
      {
        Vscode.window.showErrorMessage("Cannot start debugger: The cpptools extension was not found but ${cpptools} was found");
        return Promise.reject('cpptools was not found');
      }
      debugConfiguration.hx_debuggerPath = [ for (arg in debugConfiguration.hx_debuggerPath) arg.replace("${cpptools}", ext.extensionPath) ];
    }

		final vshaxe:Vshaxe = Vscode.extensions.getExtension("nadako.vshaxe").exports;
    if (debugConfiguration.hx_haxeExecutable == null)
    {
      debugConfiguration.hx_haxeExecutable = vshaxe.haxeExecutable.configuration;
    }

    if (debugConfiguration.hx_haxeConfiguration == null)
    {
      final path:Array<Array<String>> = Vscode.workspace.getConfiguration('haxe').get('configurations');
      if (path != null && path.length > 0)
      {
        debugConfiguration.hx_haxeConfiguration = path[0];
      }
    }
    return debugConfiguration;
  }
}