import Foundation
import Combine
import RxSwift

extension Effect {
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
