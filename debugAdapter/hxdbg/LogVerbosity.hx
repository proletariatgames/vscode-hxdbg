package hxdbg;

enum abstract LogVerbosity(String) from String
{
  var VeryVerbose = "VeryVerbose";
  var Verbose = "Verbose";
  var Debug = "Debug";
  var Log = "Log";
  var Warning = "Warning";
  var Error = "Error";
  var Failure = "Failure";

  @:op(A >= B) public function isAsVerbose(asVerbosity:LogVerbosity):Bool
  {
    if (this == asVerbosity)
    {
      return true;
    }
    return toInt() >= asVerbosity.toInt();
  }

  @:op(A < B) inline public function isLessVerbose(asVerbosity:LogVerbosity):Bool
  {
    return !isAsVerbose(asVerbosity);
  }

  inline public function isValid()
  {
    return toInt() >= 0;
  }

  public function toInt()
  {
    return switch (this : LogVerbosity) {
      case VeryVerbose: 0;
      case Verbose: 1;
      case Debug: 2;
      case Log: 3;
      case Warning: 4;
      case Error: 5;
      case Failure: 6;
      case _: -1;
    }
  }
}