package hxdbg;

#if !macro
import js.node.stream.Writable.IWritable;
using StringTools;
#else
import haxe.macro.Expr;
#end

class Log
{
  #if !macro
  public static final verbosity:LogVerbosity = #if debug Verbose #else Warning #end;

  private static var logFile:Null<IWritable>;
  public static function init()
  {
    haxe.Log.trace = (v:Dynamic, ?pos:haxe.PosInfos) -> {
      var str = Std.string(v);
      var extra = pos.customParams == null ? '' : (', ' + pos.customParams.join(', '));
      var prefix = pos.fileName + ':' + pos.lineNumber +': ';
      if ((str : LogVerbosity).isValid() && (str : LogVerbosity) < verbosity)
      {
        return;
      }
      var data = '$prefix$str$extra';
      data.replace('\n', '\n\t');
      data += '\n';
      switch (str) {
        case 'Error' | 'Warning':
          HxDebug.instance.sendEvent(new adapter.DebugSession.OutputEvent(data, stderr));
        case _:
          // this.sendEvent(new adapter.DebugSession.OutputEvent(prefix + str + extra + '\n'));
      }
      js.Node.process.stderr.write(data);
      if (logFile != null)
      {
        logFile.write(data);
      }
    };
  }

  public static function end(?cb:Void->Void)
  {
    if (logFile != null)
    {
      logFile.end(cb);
    } else if (cb != null) {
      cb();
    }
  }

  public static function initLogFile(file:String)
  {
    if (logFile != null)
    {
      logFile.end();
    }
    logFile = js.node.Fs.createWriteStream(file, { flags:WriteCreate });
  }

  #else
  static function makeLog(kind:Expr, args:Array<Expr>)
  {
    var pos = haxe.macro.Context.currentPos();
    var call = { expr:ECall(macro @:pos(pos) trace, [kind].concat(args)), pos:pos };
    return macro @:pos(pos) if ($kind >= hxdbg.Log.verbosity) $call;
  }
  #end

  macro public static function vverb(args:Array<Expr>)
  {
    return makeLog(macro hxdbg.LogVerbosity.VeryVerbose, args);
  }

  macro public static function verb(args:Array<Expr>)
  {
    return makeLog(macro hxdbg.LogVerbosity.Verbose, args);
  }

  macro public static function debug(args:Array<Expr>)
  {
    return makeLog(macro hxdbg.LogVerbosity.Debug, args);
  }

  macro public static function log(args:Array<Expr>)
  {
    return makeLog(macro hxdbg.LogVerbosity.Log, args);
  }

  macro public static function warn(args:Array<Expr>)
  {
    return makeLog(macro hxdbg.LogVerbosity.Warning, args);
  }

  macro public static function err(args:Array<Expr>)
  {
    return makeLog(macro hxdbg.LogVerbosity.Error, args);
  }
}