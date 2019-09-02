package hxdbg;
import protocol.debug.Types.Source;
using StringTools;

enum SourceKind
{
  HaxeCompiled(haxeInfo:HaxeSourceInfo);
  HaxeCppia;
  Passthrough;
}

typedef SourceType = {
  var kind:SourceKind;
  var source:Source;
};

typedef HaxeSourceInfo = {
};

class Sources
{
  public final ctx:Context;
  var cached:Map<String, SourceType>;

  public function new(ctx)
  {
    this.ctx = ctx;
  }

  public function isHaxeSource(s:Source)
  {
    if (s.name != null && s.name.toLowerCase().endsWith('.hx'))
    {
      return true;
    } else if (s.path != null && s.path.toLowerCase().endsWith('.hx')) {
      return true;
    } else if (s.sourceReference > 0) {
      return false; // source references are never used in this debugger yet
    } else {
      return false;
    }
  }

  // public function get
}