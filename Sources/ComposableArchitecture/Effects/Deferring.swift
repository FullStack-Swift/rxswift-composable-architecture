import Foundation
import Combine
import RxSwift

extension Effect {
    /// Returns an effect that will be executed after given `dueTime`.
    ///
    /// ```swift
    /// case let .textChanged(text):
    ///   return environment.search(text)
    ///     .deferred(for: 0.5, scheduler: environment.mainQueue)
    ///     .map(Action.searchResponse)
    /// ```
    ///
    /// - Parameters:
    ///   - upstream: the effect you want to defer.
    ///   - dueTime: The duration you want to defer for.
    ///   - scheduler: The scheduler you want to deliver the defer output to.
    ///   - options: Scheduler options that customize the effect's delivery of elements.
    /// - Returns: An effect that will be executed after `dueTime`
  public func deferred<S: SchedulerType>(
    for dueTime: RxTimeInterval,
    scheduler: S
  ) -> Effect {
    Observable.deferred {
      Observable.just(())
        .delay(dueTime, scheduler: scheduler)
        .flatMap { () in
          observe(on: scheduler)
        }
    }
    .eraseToEffect()
  }
}
