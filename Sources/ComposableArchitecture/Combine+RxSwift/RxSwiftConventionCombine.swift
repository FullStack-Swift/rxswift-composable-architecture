import Foundation

public typealias AnyCancellable = AnyDisposable

public enum RxCombine {
  
  /// A signal that a publisher doesn’t produce additional elements, either due to normal completion or an error.
  public enum Completion<Failure> where Failure: Error {
    
    /// The publisher finished normally.
    case finished
    
    /// The publisher stopped publishing due to the indicated error.
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
  func send(completion: RxCombine.Completion<any Error>) {
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
  /**
   Returns the elements from the source observable sequence until the other observable sequence produces an element.
   
   - seealso: [takeUntil operator on reactivex.io](http://reactivex.io/documentation/operators/takeuntil.html)
   
   - parameter other: Observable sequence that terminates propagation of elements of the source sequence.
   - returns: An observable sequence containing the elements of the source sequence up to the point the other sequence interrupted further propagation.
   */
  func prefix(untilOutputFrom: any ObservableType) -> Observable<Element> {
    take(until: untilOutputFrom)
  }
  
  /// Omits the specified number of elements before republishing subsequent elements.
  ///
  /// Use ``Publisher/dropFirst(_:)`` when you want to drop the first `n` elements from the upstream publisher, and republish the remaining elements.
  ///
  /// The example below drops the first five elements from the stream:
  ///
  ///     let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  ///     cancellable = numbers.publisher
  ///         .dropFirst(5)
  ///         .sink { print("\($0)", terminator: " ") }
  ///
  ///     // Prints: "6 7 8 9 10 "
  ///
  /// - Parameter count: The number of elements to omit. The default is `1`.
  /// - Returns: A publisher that doesn’t republish the first `count` elements.
  func dropFirst(_ count: Int = 1) -> Observable<Element> {
    skip(1)
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
    receiveCompletion: ((RxCombine.Completion<any Error>) -> Void)? = nil,
    receiveCancel: (() -> Void)? = nil,
    receiveRequest: ((()) -> Void)? = nil
  ) -> Observable<Element> {
    return self.asPublisher()
      .handleEvents { _ in
        receiveSubscription?(())
      } receiveOutput: { ouput in
        receiveOutput?(ouput)
      } receiveCompletion: { completion in
        switch completion {
          case .failure(let error):
            receiveCompletion?(.failure(error))
          case .finished:
            receiveCompletion?(.finished)
        }
      } receiveCancel: {
        receiveCancel?()
      } receiveRequest: { _ in
        receiveRequest?(())
      }
      .asObservable()
  }
}

extension ObservableType {
  public func sink(
    receiveCompletion: @escaping ((RxCombine.Completion<Error>) -> Void),
    receiveValue: @escaping ((Self.Element) -> Void))
  -> Disposable {
    subscribe { element in
      receiveValue(element)
    } onError: { error in
      receiveCompletion(.failure(error))
    } onCompleted: {
      receiveCompletion(.finished)
    }
  }

  public func sink(
    receiveValue: @escaping ((Element) -> Void)
  ) -> Disposable {
    subscribe(onNext: receiveValue)
  }

  public func eraseToAnyPublisher() -> Observable<Element> {
    asObservable()
  }
  
  public func removeDuplicates(
    by predicate: @escaping (Element, Element) throws -> Bool
  ) -> Observable<Element> {
    distinctUntilChanged(predicate)
  }
}

public extension Disposable {
  func cancel() {
    dispose()
  }
}


#if canImport(Combine)
import Combine

extension Effect {
  /// Creates an effect from a Combine publisher.
  ///
  /// - Parameter createPublisher: The closure to execute when the effect is performed.
  /// - Returns: An effect wrapping a Combine publisher.
  public static func publisher<P: Publisher>(_ createPublisher: @escaping () -> P) -> Self
  where P.Output == Action, P.Failure == Never {
    Self(
      operation: .publisher(
        withEscapedDependencies { continuation in
          Deferred {
            continuation.yield {
              createPublisher()
            }
          }
        }
          .eraseToAnyPublisher()
          .asObservable()
      )
    )
  }
}
#endif
