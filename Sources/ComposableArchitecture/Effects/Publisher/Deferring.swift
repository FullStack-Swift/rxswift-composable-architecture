import RxSwift

extension EffectPublisher {
  /// Returns an effect that will be executed after given `dueTime`.
  ///
  /// ```swift
  /// case let .textChanged(text):
  ///   return self.apiClient.search(text)
  ///     .deferred(for: 0.5, scheduler: self.mainQueue)
  ///     .map(Action.searchResponse)
  /// ```
  ///
  /// - Parameters:
  ///   - dueTime: The duration you want to defer for.
  ///   - scheduler: The scheduler you want to deliver the defer output to.
  ///   - options: Scheduler options that customize the effect's delivery of elements.
  /// - Returns: An effect that will be executed after `dueTime`
  @available(
    iOS, deprecated: 9999.0, message: "Use 'clock.sleep' in `Effect.task` or 'Effect.run', instead."
  )
  @available(
    macOS, deprecated: 9999.0,
    message: "Use 'clock.sleep' in `Effect.task` or 'Effect.run', instead."
  )
  @available(
    tvOS, deprecated: 9999.0,
    message: "Use 'clock.sleep' in `Effect.task` or 'Effect.run', instead."
  )
  @available(
    watchOS, deprecated: 9999.0,
    message: "Use 'clock.sleep' in `Effect.task` or 'Effect.run', instead."
  )
  public func deferred<S: SchedulerType>(
    for dueTime: RxTimeInterval,
    scheduler: S
  ) -> Self {
    switch self.operation {
      case .none:
        return .none
      case .publisher, .run:
        return Self(
          operation: .publisher(
            Observable.just(())
              .delay(dueTime, scheduler: scheduler)
              .flatMap { () in
                observe(on: scheduler)
              }
              .eraseToAnyPublisher()
          )
        )
    }
  }
}
