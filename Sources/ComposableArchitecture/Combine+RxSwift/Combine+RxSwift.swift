#if canImport(Combine)
import Combine
import RxSwift

public extension Publisher {
    /// Convert the publisher to an Observable
    /// - Returns: Observable
  func asObservable() -> Observable<Output> {
    Observable<Output>.create { observer in
      let cancellable = self.sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            observer.onCompleted()
          case .failure(let error):
            observer.onError(error)
          }
        },
        receiveValue: { value in
          observer.onNext(value)
        })
      return Disposables.create { cancellable.cancel() }
    }
  }
    /// Convert the publisher to an Effect
    /// - Returns: Effect
  func eraseToEffect() -> Effect<Output> {
    Effect(asObservable())
  }
}

public extension ObservableConvertibleType {
  
    ///  Convert the observable to an AnyPublisher
  var publisher: AnyPublisher<Element, Swift.Error> {
    RxPublisher(upstream: self).eraseToAnyPublisher()
  }

    ///  Convert the observable to an AnyPublisher
    /// - Returns: AnyPublisher
  func asPublisher() -> AnyPublisher<Element, Swift.Error> {
    publisher
  }
}

  /// RxPublisher
public class RxPublisher<Upstream: ObservableConvertibleType>: Publisher {
  public typealias Output = Upstream.Element
  public typealias Failure = Swift.Error
  
  private let upstream: Upstream
  init(upstream: Upstream) {
    self.upstream = upstream
  }
  
  public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
    subscriber.receive(subscription: RxSubscription(upstream: upstream,
                                                    downstream: subscriber))
  }
}

  /// RxSubscription
class RxSubscription<Upstream: ObservableConvertibleType, Downstream: Subscriber>: Combine.Subscription where Downstream.Input == Upstream.Element, Downstream.Failure == Swift.Error {
  private var disposable: Disposable?
  private let buffer: DemandBuffer<Downstream>
  
  init(upstream: Upstream, downstream: Downstream) {
    buffer = DemandBuffer(subscriber: downstream)
    disposable = upstream.asObservable().subscribe(bufferRxEvents)
  }
  
  private func bufferRxEvents(_ event: RxSwift.Event<Upstream.Element>) {
    switch event {
    case .next(let element):
      _ = buffer.buffer(value: element)
    case .error(let error):
      buffer.complete(completion: .failure(error))
    case .completed:
      buffer.complete(completion: .finished)
    }
  }
  
  func request(_ demand: Subscribers.Demand) {
    _ = self.buffer.demand(demand)
  }
  
  func cancel() {
    disposable?.dispose()
    disposable = nil
  }
}

#endif
