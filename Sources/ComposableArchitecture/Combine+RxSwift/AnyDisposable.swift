import RxSwift

class AnyDisposable: Disposable, Hashable {
  let _dispose: () -> Void
  
  init(_ disposable: Disposable) {
    _dispose = disposable.dispose
  }
  
  func dispose() {
    _dispose()
  }
  
  static func == (lhs: AnyDisposable, rhs: AnyDisposable) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
