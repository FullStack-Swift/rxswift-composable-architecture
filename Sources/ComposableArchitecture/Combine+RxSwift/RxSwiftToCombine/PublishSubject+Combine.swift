#if canImport(Combine)
import Combine

// MARK: - Behavior Subject as Combine Subject

/// A bi-directional wrapper for a RxSwift Publish Subject
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class RxPassthroughSubject<Output>: Combine.Subject {
  private let rxSubject: PublishSubject<Output>
  private let subject = PassthroughSubject<Output, Failure>()
  private let subscription: Combine.AnyCancellable?
  
  init(rxSubject: PublishSubject<Output>) {
    self.rxSubject = rxSubject
    subscription = rxSubject.publisher.subscribe(subject)
  }
  
  public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
    subject.receive(subscriber: subscriber)
  }
  
  public func send(_ value: Output) {
    rxSubject.onNext(value)
  }
  
  public func send(completion: Subscribers.Completion<Failure>) {
    switch completion {
      case .finished:
        rxSubject.onCompleted()
      case .failure(let error):
        rxSubject.onError(error)
    }
  }
  
  public func send(subscription: Subscription) {
    subject.send(subscription: subscription)
  }
  
  deinit { subscription?.cancel() }
  
  public typealias Failure = Swift.Error
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension PublishSubject {
  func toCombine() -> RxPassthroughSubject<Element> {
    RxPassthroughSubject(rxSubject: self)
  }
}
#endif
