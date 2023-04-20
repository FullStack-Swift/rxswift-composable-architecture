import RxSwift
import Dispatch
import Foundation

extension EffectPublisher {
  /// Throttles an effect so that it only publishes one output per given interval.
  ///
  /// - Parameters:
  ///   - id: The effect's identifier.
  ///   - interval: The interval at which to find and emit the most recent element, expressed in
  ///     the time system of the scheduler.
  ///   - scheduler: The scheduler you want to deliver the throttled output to.
  ///   - latest: A boolean value that indicates whether to publish the most recent element. If
  ///     `false`, the publisher emits the first element received during the interval.
  /// - Returns: An effect that emits either the most-recent or first element received during the
  ///   specified interval.
  public func throttle<S: SchedulerType>(
    id: AnyHashable,
    for interval: RxTimeInterval,
    scheduler: S,
    latest: Bool
  ) -> Self {
    switch self.operation {
      case .none:
        return .none
      case .publisher, .run:
        return self.publisher.observe(on: scheduler)
          .flatMap { value -> Observable<Action> in
            throttleLock.lock()
            defer { throttleLock.unlock() }

            guard let throttleTime = throttleTimes[id] as! RxTime? else {
              throttleTimes[id] = scheduler.now
              throttleValues[id] = nil
              return Observable.just(value)
                .eraseToAnyPublisher()
            }

            let value = latest ? value : (throttleValues[id] as! Action? ?? value)
            throttleValues[id] = value

            guard throttleTime.distance(to: scheduler.now) < interval.timeInterval else {
              throttleTimes[id] = scheduler.now
              throttleValues[id] = nil
              return Observable.just(value)
                .eraseToAnyPublisher()
            }
            return Observable.just(value)
              .delay(
                .seconds(
                  throttleTime.addingTimeInterval(interval.timeInterval).timeIntervalSince1970
                  - scheduler.now.timeIntervalSince1970), scheduler: scheduler
              )
              .handleEvents(
                receiveOutput: { _ in
                  throttleLock.sync {
                    throttleTimes[id] = scheduler.now
                    throttleValues[id] = nil
                  }
                }
              )
              .eraseToAnyPublisher()
          }
          .eraseToEffect()
          .cancellable(id: id, cancelInFlight: true)
    }
  }

  /// Throttles an effect so that it only publishes one output per given interval.
  ///
  /// A convenience for calling ``EffectPublisher/throttle(id:for:scheduler:latest:)-3gibe`` with a
  /// static type as the effect's unique identifier.
  ///
  /// - Parameters:
  ///   - id: The effect's identifier.
  ///   - interval: The interval at which to find and emit the most recent element, expressed in
  ///     the time system of the scheduler.
  ///   - scheduler: The scheduler you want to deliver the throttled output to.
  ///   - latest: A boolean value that indicates whether to publish the most recent element. If
  ///     `false`, the publisher emits the first element received during the interval.
  /// - Returns: An effect that emits either the most-recent or first element received during the
  ///   specified interval.
  public func throttle<S: SchedulerType>(
    id: Any.Type,
    for interval: RxTimeInterval,
    scheduler: S,
    latest: Bool
  ) -> Self {
    self.throttle(id: ObjectIdentifier(id), for: interval, scheduler: scheduler, latest: latest)
  }
}

var throttleTimes: [AnyHashable: Any] = [:]
var throttleValues: [AnyHashable: Any] = [:]
let throttleLock = NSRecursiveLock()

fileprivate extension DispatchTimeInterval {
  var timeInterval: TimeInterval {
    switch self {
      case let .seconds(s):
        return TimeInterval(s)
      case let .milliseconds(ms):
        return TimeInterval(TimeInterval(ms) / 1000.0)
      case let .microseconds(us):
        return TimeInterval(Int64(us) * Int64(NSEC_PER_USEC)) / TimeInterval(NSEC_PER_SEC)
      case let .nanoseconds(ns):
        return TimeInterval(ns) / TimeInterval(NSEC_PER_SEC)
      case .never:
        return .infinity
      @unknown default:
        fatalError()
    }
  }

  static func seconds(_ interval: TimeInterval) -> DispatchTimeInterval {
    let delay = Double(NSEC_PER_SEC) * interval
    return DispatchTimeInterval.nanoseconds(Int(delay))
  }
}
