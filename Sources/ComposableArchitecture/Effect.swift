import Foundation
import RxSwift

public struct Effect<Value>: ObservableType {
  public typealias Element = Value
  public let upstream: Observable<Value>
  
  public init(_ observable: Observable<Value>) {
    self.upstream = observable
  }
  public func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer: ObserverType, Element == Observer.Element {
    upstream.subscribe(observer)
  }
  
  public init(value: Value) {
    self.init(Observable.just(value))
  }
  
  public init(error: Error) {
    self.init(Observable.error(error))
  }
  
  public static var none: Self {
    Observable.empty().eraseToEffect()
  }
  
  public static func future(_ attemptToFulfill: @escaping (@escaping (Result<Value, Error>) -> Void) -> Void) -> Self {
    Observable.create { observer in
      attemptToFulfill { result in
        switch result {
        case let .success(output):
          observer.onNext(output)
          observer.onCompleted()
        case let .failure(error):
          observer.onError(error)
        }
      }
      return Disposables.create()
    }
    .eraseToEffect()
  }
  
  public static func result(_ attemptToFulfill: @escaping () -> Result<Value, Error>) -> Self {
    Observable.create { observer in
      switch attemptToFulfill() {
      case let .success(output):
        observer.onNext(output)
        observer.onCompleted()
      case let .failure(error):
        observer.onError(error)
      }
      return Disposables.create()
    }
    .eraseToEffect()
  }
  
  public static func run(_ work: @escaping (AnyObserver<Value>) -> Disposable) -> Self {
    Observable.create(work).eraseToEffect()
  }
  
  public static func concatenate(_ effects: Effect...) -> Effect {
    .concatenate(effects)
  }
  
  public static func concatenate<C: Collection>(_ effects: C) -> Effect where C.Element == Effect {
    guard let first = effects.first else { return .none }
    return effects
      .dropFirst()
      .reduce(into: first) { effects, effect in
        effects = effects.concat(effect).eraseToEffect()
      }
  }
  
  public static func merge(_ effects: Effect...) -> Effect {
    .merge(effects)
  }
  
  public static func merge<S: Sequence>(_ effects: S) -> Effect where S.Element == Effect {
    Observable
      .merge(effects.map { $0.asObservable() })
      .eraseToEffect()
  }
  
  public static func fireAndForget(_ work: @escaping () -> Void) -> Effect {
    return Effect(
      Observable.deferred {
        work()
        return Observable<Value>.empty()
      })
  }
  
  public func map<T>(_ transform: @escaping (Value) -> T) -> Effect<T> {
    .init(self.map(transform))
  }
}

extension Effect where Value == Never {
  
  public func fireAndForget<T>() -> Effect<T> {
    func absurd<A>(_ never: Never) -> A {}
    return self.map(absurd)
  }
}

extension ObservableType {
  
  public func eraseToEffect() -> Effect<Element> {
    Effect(asObservable())
  }
  
  public func catchToEffect() -> Effect<Result<Element, Error>> {
    self.map(Result<Element, Error>.success)
      .catch { Observable<Result<Element, Error>>.just(Result.failure($0)) }
      .eraseToEffect()
  }
}

extension Observable {
  @discardableResult
  public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root,Element>, on object: Root) -> Disposable {
    subscribe(onNext: { value in
      object[keyPath: keyPath] = value
    })
  }
}
