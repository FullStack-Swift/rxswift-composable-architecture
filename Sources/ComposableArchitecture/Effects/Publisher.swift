import RxRelay

extension Effect {
  /// Creates an effect from a Combine publisher.
  ///
  /// - Parameter createPublisher: The closure to execute when the effect is performed.
  /// - Returns: An effect wrapping a Combine publisher.
  public static func publisher<P: Observable<Action>>(
    _ createPublisher: @escaping () -> P
  ) -> Self {
    Self(
      operation: .publisher(
        withEscapedDependencies { continuation in
          Observable.deferred {
            continuation.yield {
              createPublisher()
            }
          }
        }
      )
    )
  }
}

public struct _EffectPublisher<Action>: ObservableType {

  public typealias Element = Action

  
  let effect: Effect<Action>
  
  public init(_ effect: Effect<Action>) {
    self.effect = effect
  }
  
  public func subscribe<Observer>(
    _ observer: Observer
  ) -> RxSwift.Disposable where Observer : RxSwift.ObserverType, Action == Observer.Element {
    self.publisher.subscribe(observer)
  }

  var publisher: Observable<Action> {
    switch self.effect.operation {
      case .none:
        return Observable.empty()
      case let .publisher(publisher):
        return publisher
      case let .run(priority, operation):
        return Observable.create { subscriber in
          let task = Task(priority: priority) { @MainActor in
            defer { subscriber.onCompleted() }
            await operation(Send { subscriber.send($0) })
          }
          return AnyCancellable {
            task.cancel()
          }
        }
    }
  }
}
