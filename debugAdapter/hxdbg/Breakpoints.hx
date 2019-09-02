package hxdbg;

import protocol.debug.Types.SetBreakpointsResponse;
import protocol.debug.Types.SetBreakpointsArguments;
import protocol.debug.Types.Breakpoint;
import hxdbg.helpers.SequenceHandler;

enum BreakpointOnBreak
{
  Internal(fn:Void->Void);
  Normal;
  Conditional(exprCondition:String);
}

enum BreakpointKind
{
  LineBr(file:String, line:Int);
  FuncBr(cls:String, fn:String);
}

enum BreakpointStatus
{
  Sending;
  Active;
  Disabled;
  NotFound;
  // Error(msg:debugger.IController.Message);
  CustomError(msg:String);
}

typedef BreakpointType = {
  id:Int,

  on_break:Array<BreakpointOnBreak>,
  kind:BreakpointKind,
  status:BreakpointStatus,
  breakpoint:Breakpoint
}

class Breakpoints implements com.dongxiguo.continuation.Async
{
  public final ctx:Context;
  final seq:SequenceHandler<Breakpoint> = new SequenceHandler();
  final breakpoints:Map<Int, BreakpointType> = new Map();

  public function new(ctx)
  {
    this.ctx = ctx;
  }

  @async public function setBreakpoints(req:SetBreakpointsArguments):SetBreakpointsResponse
  {
    var isHaxe = ctx.sources.isHaxeSource(req.source);
    if (!isHaxe)
    {
      var ret:SetBreakpointsResponse = @await ctx.wrapped.sendRequest(req);
      if (ret.body != null && ret.body.breakpoints != null)
      // {
        var newBreakpoints = [];
        for (br in ret.body.breakpoints)
        {
          var cur = this.seq.getCur(br);
          newBreakpoints.push(cur);
          if (!breakpoints.exists(cur.id))
          {
            break
          }
        }
        ret.body.breakpoints = newBreakpoints;
      }
      return ret;
    } else {
      // if (ctx.sources.)
    }
    return null;
  }
}