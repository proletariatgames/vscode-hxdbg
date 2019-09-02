package hxdbg;

enum Result<T>
{
  Success(result:T);
  Error(err:js.lib.Error);
}