#if canImport(Combine)
import Combine
import RxSwift

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
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
  
  func eraseToEffect() -> Effect<Output> {
    Effect(asObservable())
  }
}
#endif

#if canImport(Combine)
import Combine
import RxSwift

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension ObservableConvertibleType {
  
  var publisher: AnyPublisher<Element, Swift.Error> {
    RxPublisher(upstream: self).eraseToAnyPublisher()
  }
  
  func asPublisher() -> AnyPublisher<Element, Swift.Error> {
    publisher
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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

#if canImport(Combine)
import Combine
import class Foundation.NSRecursiveLock

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class DemandBuffer<S: Subscriber> {
  private let lock = NSRecursiveLock()
  private var buffer = [S.Input]()
  private let subscriber: S
  private var completion: Subscribers.Completion<S.Failure>?
  private var demandState = Demand()
  
  init(subscriber: S) {
    self.subscriber = subscriber
  }
  
  func buffer(value: S.Input) -> Subscribers.Demand {
    precondition(self.completion == nil,"completion == nil")
    switch demandState.requested {
    case .unlimited:
      return subscriber.receive(value)
    default:
      buffer.append(value)
      return flush()
    }
  }
  
  func complete(completion: Subscribers.Completion<S.Failure>) {
    precondition(self.completion == nil,"self.completion == nil")
    self.completion = completion
    _ = flush()
  }
  
  func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
    flush(adding: demand)
  }
  
  private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
    lock.lock()
    defer { lock.unlock() }
    if let newDemand = newDemand {
      demandState.requested += newDemand
    }
    guard demandState.requested > 0 || newDemand == Subscribers.Demand.none else { return .none }
    while !buffer.isEmpty && demandState.processed < demandState.requested {
      demandState.requested += subscriber.receive(buffer.remove(at: 0))
      demandState.processed += 1
    }
    if let completion = completion {
      buffer = []
      demandState = .init()
      self.completion = nil
      subscriber.receive(completion: completion)
      return .none
    }
    let sentDemand = demandState.requested - demandState.sent
    demandState.sent += sentDemand
    return sentDemand
  }
}

// MARK: - Private Helpers
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension DemandBuffer {
  struct Demand {
    var processed: Subscribers.Demand = .none
    var requested: Subscribers.Demand = .none
    var sent: Subscribers.Demand = .none
  }
}
#endif
