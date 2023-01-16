import RxRelay
import RxSwift
import SwiftUI

extension EffectPublisher {
  /// Wraps the emission of each element with SwiftUI's `withAnimation`.
  ///
  /// ```swift
  /// case .buttonTapped:
  ///   return .task {
  ///     .activityResponse(await self.apiClient.fetchActivity())
  ///   }
  ///   .animation()
  /// ```
  ///
  /// - Parameter animation: An animation.
  /// - Returns: A publisher.
  public func animation(_ animation: Animation? = .default) -> Self {
    self.transaction(Transaction(animation: animation))
  }

  /// Wraps the emission of each element with SwiftUI's `withTransaction`.
  ///
  /// ```swift
  /// case .buttonTapped:
  ///   var transaction = Transaction(animation: .default)
  ///   transaction.disablesAnimations = true
  ///   return .task {
  ///     .activityResponse(await self.apiClient.fetchActivity())
  ///   }
  ///   .transaction(transaction)
  /// ```
  ///
  /// - Parameter transaction: A transaction.
  /// - Returns: A publisher.
  public func transaction(_ transaction: Transaction) -> Self {
    switch self.operation {
    case .none:
      return .none
    case let .publisher(publisher):
      return Self(
        operation: .publisher(
          TransactionPublisher(upstream: publisher, transaction: transaction).asObservable()
        )
      )
    case let .run(priority, operation):
      return Self(
        operation: .run(priority) { send in
          await operation(
            Send { value in
              withTransaction(transaction) {
                send(value)
              }
            }
          )
        }
      )
    }
  }
}

private struct TransactionPublisher<Action>: ObservableType {

  typealias Element = Action

  var upstream: Observable<Action>
  var transaction: Transaction

  init(upstream: Observable<Action>, transaction: Transaction) {
    self.upstream = upstream
    self.transaction = transaction
  }

  func subscribe<Observer>(_ observer: Observer) -> RxSwift.Disposable where Observer : RxSwift.ObserverType, Element == Observer.Element {
    upstream.subscribe(observer)
  }


}
