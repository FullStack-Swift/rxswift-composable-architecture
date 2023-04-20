import RxSwift

public class AnyDisposable: Disposable, Hashable {
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
  
  public static func == (lhs: AnyDisposable, rhs: AnyDisposable) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
