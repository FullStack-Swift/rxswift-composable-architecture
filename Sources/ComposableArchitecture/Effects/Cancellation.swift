//import Foundation
//import RxSwift
//
//extension Effect {
//    /// Turns an effect into one that is capable of being canceled.
//    ///
//    /// To turn an effect into a cancellable one you must provide an identifier, which is used in
//    /// ``Effect/cancel(id:)`` to identify which in-flight effect should be canceled. Any hashable
//    /// value can be used for the identifier, such as a string, but you can add a bit of protection
//    /// against typos by defining a new type that conforms to `Hashable`, such as an empty struct:
//    ///
//    /// ```swift
//    /// struct LoadUserId: Hashable {}
//    ///
//    /// case .reloadButtonTapped:
//    ///   // Start a new effect to load the user
//    ///   return environment.loadUser
//    ///     .map(Action.userResponse)
//    ///     .cancellable(id: LoadUserId(), cancelInFlight: true)
//    ///
//    /// case .cancelButtonTapped:
//    ///   // Cancel any in-flight requests to load the user
//    ///   return .cancel(id: LoadUserId())
//    /// ```
//    ///
//    /// - Parameters:
//    ///   - id: The effect's identifier.
//    ///   - cancelInFlight: Determines if any in-flight effect with the same identifier should be
//    ///     canceled before starting this new one.
//    /// - Returns: A new effect that is capable of being canceled by an identifier.
//  public func cancellable(id: AnyHashable, cancelInFlight: Bool = false) -> Effect {
//    let effect = Observable<Value>.deferred {
//      cancellablesLock.lock()
//      defer { cancellablesLock.unlock() }
//
//      let subject = PublishSubject<Value>()
//      var values: [Value] = []
//      var isCaching = true
//      let disposable =
//      self
//        .do(onNext: { val in
//          guard isCaching else { return }
//          values.append(val)
//        })
//          .subscribe(subject)
//
//          var cancellationDisposable: AnyDisposable!
//          cancellationDisposable = AnyDisposable(
//            Disposables.create {
//              cancellablesLock.sync {
//                subject.onCompleted()
//                disposable.dispose()
//                cancellationCancellables[id]?.remove(cancellationDisposable)
//                if cancellationCancellables[id]?.isEmpty == .some(true) {
//                  cancellationCancellables[id] = nil
//                }
//              }
//            })
//
//          cancellationCancellables[id, default: []].insert(
//            cancellationDisposable
//          )
//
//          return Observable.from(values)
//          .concat(subject)
//          .do(
//            onError: { _ in cancellationDisposable.dispose() },
//            onCompleted: cancellationDisposable.dispose,
//            onSubscribed: { isCaching = false },
//            onDispose: cancellationDisposable.dispose
//          )
//            }
//      .eraseToEffect()
//    return cancelInFlight ? .concatenate(.cancel(id: id), effect) : effect
//  }
//
//    /// An effect that will cancel any currently in-flight effect with the given identifier.
//    ///
//    /// - Parameter id: An effect identifier.
//    /// - Returns: A new effect that will cancel any currently in-flight effect with the given
//    ///   identifier.
//  public static func cancel(id: AnyHashable) -> Effect {
//    return .fireAndForget {
//      cancellablesLock.sync {
//        cancellationCancellables[id]?.forEach { $0.dispose() }
//      }
//    }
//  }
//    /// An effect that will cancel multiple currently in-flight effects with the given identifiers.
//    ///
//    /// - Parameter ids: A variadic list of effect identifiers.
//    /// - Returns: A new effect that will cancel any currently in-flight effects with the given
//    ///   identifiers.
//    public static func cancel(ids: AnyHashable...) -> Effect {
//      .cancel(ids: ids)
//    }
//
//    /// An effect that will cancel multiple currently in-flight effects with the given identifiers.
//    ///
//    /// - Parameter ids: An array of effect identifiers.
//    /// - Returns: A new effect that will cancel any currently in-flight effects with the given
//    ///   identifiers.
//    public static func cancel(ids: [AnyHashable]) -> Effect {
//      .merge(ids.map(Effect.cancel(id:)))
//    }
//}
//
//var cancellationCancellables: [AnyHashable: Set<AnyDisposable>] = [:]
//let cancellablesLock = NSRecursiveLock()
