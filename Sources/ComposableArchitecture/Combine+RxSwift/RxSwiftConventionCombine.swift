import RxSwift
import Foundation

public enum RxSwiftConventionCombine {
  public enum Completion<Failure> where Failure : Error {
    case finished
    case failure(Failure)

    public init(failure: Failure) {
      self = .failure(failure)
    }
  }
}

public extension ObserverType {
  /// Convenience method equivalent to `on(.next(element: Element))`
  ///
  /// - parameter element: Next element to send to observer(s)
  func send(_ element: Element) {
    onNext(element)
  }
  /// - Completion.finished:  Convenience method equivalent to `on(.completed)`
  /// - Completion.failure: Convenience method equivalent to `on(.error(Swift.Error))`
  /// - parameter completion: Completion to send to observer(s)
  func send(completion: RxSwiftConventionCombine.Completion<Error>) {
    switch completion {
      case .finished:
        onCompleted()
      case .failure(let failure):
        onError(failure)
    }
  }
}

public extension ObserverType where Element == Void {
  func send() {
    onNext(())
  }
}

public extension ObservableType {
  func prefix(untilOutputFrom: any ObservableType) -> Observable<Element> {
    take(until: untilOutputFrom)
  }

  /// Performs the specified closures when publisher events occur.
  ///
  /// Use ``Publisher/handleEvents(receiveSubscription:receiveOutput:receiveCompletion:receiveCancel:receiveRequest:)`` when you want to examine elements as they progress through the stages of the publisher’s lifecycle.
  ///
  /// In the example below, a publisher of integers shows the effect of printing debugging information at each stage of the element-processing lifecycle:
  ///
  ///     let integers = (0...2)
  ///     cancellable = integers.publisher
  ///         .handleEvents(receiveSubscription: { subs in
  ///             print("Subscription: \(subs.combineIdentifier)")
  ///         }, receiveOutput: { anInt in
  ///             print("in output handler, received \(anInt)")
  ///         }, receiveCompletion: { _ in
  ///             print("in completion handler")
  ///         }, receiveCancel: {
  ///             print("received cancel")
  ///         }, receiveRequest: { (demand) in
  ///             print("received demand: \(demand.description)")
  ///         })
  ///         .sink { _ in return }
  ///
  ///     // Prints:
  ///     //   received demand: unlimited
  ///     //   Subscription: 0x7f81284734c0
  ///     //   in output handler, received 0
  ///     //   in output handler, received 1
  ///     //   in output handler, received 2
  ///     //   in completion handler
  ///
  ///
  /// - Parameters:
  ///   - receiveSubscription: An optional closure that executes when the publisher receives the subscription from the upstream publisher. This value defaults to `nil`.
  ///   - receiveOutput: An optional closure that executes when the publisher receives a value from the upstream publisher. This value defaults to `nil`.
  ///   - receiveCompletion: An optional closure that executes when the upstream publisher finishes normally or terminates with an error. This value defaults to `nil`.
  ///   - receiveCancel: An optional closure that executes when the downstream receiver cancels publishing. This value defaults to `nil`.
  ///   - receiveRequest: An optional closure that executes when the publisher receives a request for more elements. This value defaults to `nil`.
  /// - Returns: A publisher that performs the specified closures when publisher events occur.
  func handleEvents(
    receiveSubscription: ((()) -> Void)? = nil,
    receiveOutput: ((Element) -> Void)? = nil,
    receiveCompletion: ((RxSwiftConventionCombine.Completion<Error>) -> Void)? = nil,
    receiveCancel: (() -> Void)? = nil,
    receiveRequest: ((()) -> Void)? = nil
  ) -> Observable<Element> {
    self.do { onNextValue in
      receiveOutput?(onNextValue)
      receiveRequest?(())
    } onError: { error in
      receiveCompletion?(.failure(error))
    } onCompleted: {
      receiveCompletion?(.finished)
    } onSubscribe: {
      receiveSubscription?(())
    }
  }
}

public extension ObservableType {
  func sink(receiveValue: @escaping ((Element) -> Void)) -> Disposable {
    subscribe(onNext: receiveValue)
  }

  func eraseToAnyPublisher() -> Observable<Element> {
    self.asObservable()
  }
}

public extension Disposable {
  func cancel() {
    dispose()
  }
}
