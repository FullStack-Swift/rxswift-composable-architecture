import Foundation
import RxSwift
import Dispatch

extension Effect {
    func throttle(
        id: AnyHashable,
        for interval: RxTimeInterval,
        scheduler: SchedulerType,
        latest: Bool
    ) -> Effect {
        self.flatMap { value -> Observable<Value> in
            guard let throttleTime = throttleTimes[id] as! RxTime? else {
                throttleTimes[id] = scheduler.now
                throttleValues[id] = nil
                return Observable.just(value)
            }
            
            guard scheduler.now.timeIntervalSince1970 - throttleTime.timeIntervalSince1970 < interval.timeInterval else {
                throttleTimes[id] = scheduler.now
                throttleValues[id] = nil
                return Observable.just(value)
            }
            let value = latest ? value : (throttleValues[id] as! Value? ?? value)
            throttleValues[id] = value
            return Observable.just(value)
                .delay(
                    .seconds(
                        throttleTime.addingTimeInterval(interval.timeInterval).timeIntervalSince1970
                        - scheduler.now.timeIntervalSince1970), scheduler: scheduler)
        }
        .eraseToEffect()
        .cancellable(id: id, cancelInFlight: true)
    }
}

extension DispatchTimeInterval {
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

var throttleTimes: [AnyHashable: Any] = [:]
var throttleValues: [AnyHashable: Any] = [:]
let throttleLock = NSRecursiveLock()
