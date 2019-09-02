package hxdbg.helpers;

class SequenceHandler<T : { id:Int }>
{
  public var curSequence(default, null):Int = 1;

  final nativeToCurMap:Map<Int, T> = new Map();
  final curToNativeMap:Map<Int, T> = new Map();
  final nativesMap:Map<Int, T> = new Map();
  final cursMap:Map<Int, T> = new Map();

  public function new()
  {
  }

  public function removeNative(native:T)
  {
    var cur = nativeToCurMap[native.id];
    if (cur != null)
    {
      curToNativeMap.remove(cur.id);
      cursMap.remove(cur.id);
    }
    nativeToCurMap.remove(native.id);
    nativesMap.remove(native.id);
  }

  public function removeCur(cur:T)
  {
    var native = curToNativeMap[cur.id];
    if (native != null)
    {
      nativesMap.remove(native.id);
      nativeToCurMap.remove(native.id);
    }
    curToNativeMap.remove(cur.id);
    nativesMap.remove(cur.id);
  }

  inline public function natives()
  {
    return nativesMap.iterator();
  }

  inline public function curs()
  {
    return cursMap.iterator();
  }

  public function register(cur:T, native:T)
  {
    var existing = nativeToCurMap[native.id];
    if (existing != null && existing != cur)
    {
      Log.err('Trying to register an already registered breakpoint cur=$cur native=$native');
      return;
    }
    cur.id = this.curSequence++;
    nativeToCurMap[native.id] = cur;
    curToNativeMap[cur.id] = native;
    nativesMap[native.id] = native;
    cursMap[cur.id] = cur;
  }

  public function getCur(obj:T):T
  {
    var cur = nativeToCurMap[obj.id];
    if (cur == null)
    {
      cur = nativeToCur(obj);
      this.register(cur, obj);
    }
    return cur;
  }

  public function getNative(obj:T):T
  {
    return curToNativeMap[obj.id];
  }

  dynamic public function nativeToCur(obj:T):T
  {
    return Reflect.copy(obj);
  }
}