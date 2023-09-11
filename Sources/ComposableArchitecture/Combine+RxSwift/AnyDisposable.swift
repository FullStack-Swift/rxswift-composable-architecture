final public class AnyDisposable: Disposable, Hashable {
  let _dispose: () -> Void
  
  init(_ disposable: Disposable) {
    _dispose = disposable.dispose
  }

  init (_ _dispose: @escaping () -> Void) {
    self._dispose = _dispose
  }
  
  public func dispose() {
    _dispose()
  }

  deinit {
    dispose()
  }
  
  public static func == (lhs: AnyDisposable, rhs: AnyDisposable) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

extension Disposable {
  public func store(in set: inout Set<AnyDisposable>) {
    set.insert(AnyDisposable(self))
  }
  
  public func store(in disposeBag: DisposeBag) {
    disposeBag.insert(self)
  }
  
  public func store(in disposeBag: inout DisposeBag) {
    disposeBag.insert(self)
  }
}

#if(canImport(Combine))
import Combine

extension Cancellable {
  public func store(in set: inout Set<AnyDisposable>) {
    set.insert(AnyDisposable{ self.cancel() })
  }
}
#endif
