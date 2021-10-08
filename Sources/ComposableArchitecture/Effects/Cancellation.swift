import Foundation
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

extension Effect {
  public func cancellable(id: AnyHashable, cancelInFlight: Bool = false) -> Effect {
    let effect = Observable<Value>.deferred {
      cancellablesLock.lock()
      defer { cancellablesLock.unlock() }

      let subject = PublishSubject<Value>()
      var values: [Value] = []
      var isCaching = true
      let disposable =
        self
        .do(onNext: { val in
          guard isCaching else { return }
          values.append(val)
        })
        .subscribe(subject)

      var cancellationDisposable: AnyDisposable!
      cancellationDisposable = AnyDisposable(
        Disposables.create {
          cancellablesLock.sync {
            subject.onCompleted()
            disposable.dispose()
            cancellationCancellables[id]?.remove(cancellationDisposable)
            if cancellationCancellables[id]?.isEmpty == .some(true) {
              cancellationCancellables[id] = nil
            }
          }
        })

      cancellationCancellables[id, default: []].insert(
        cancellationDisposable
      )

      return Observable.from(values)
        .concat(subject)
        .do(
          onError: { _ in cancellationDisposable.dispose() },
          onCompleted: cancellationDisposable.dispose,
          onSubscribed: { isCaching = false },
          onDispose: cancellationDisposable.dispose
        )
    }
    .eraseToEffect()
    return cancelInFlight ? .concatenate(.cancel(id: id), effect) : effect
  }
  
  public static func cancel(id: AnyHashable) -> Effect {
    return .fireAndForget {
      cancellablesLock.sync {
        cancellationCancellables[id]?.forEach { $0.dispose() }
      }
    }
  }
}

var cancellationCancellables: [AnyHashable: Set<AnyDisposable>] = [:]
let cancellablesLock = NSRecursiveLock()
