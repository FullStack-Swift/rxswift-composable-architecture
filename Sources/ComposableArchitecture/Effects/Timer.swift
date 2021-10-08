import Foundation
import RxSwift

extension Effect where Value: RxAbstractInteger {
  public static func timer(
    id: AnyHashable,
    every interval: RxTimeInterval,
    on scheduler: SchedulerType
  ) -> Effect {

    return
      Observable
      .interval(interval, scheduler: scheduler)
      .eraseToEffect()
      .cancellable(id: id)
  }
}
