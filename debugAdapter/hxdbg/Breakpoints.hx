package hxdbg;

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

typedef Breakpoint = {
  id:Int,
  ?wrapped_id:Null<Int>,

  on_break:Array<BreakpointOnBreak>,
  kind:BreakpointKind,
  status:BreakpointStatus,
}