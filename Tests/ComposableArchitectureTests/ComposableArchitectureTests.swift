import ComposableArchitecture
import RxTest
import XCTest

final class ComposableArchitectureTests: XCTestCase {

//  func testScheduling() {
//    enum CounterAction: Equatable {
//      case incrAndSquareLater
//      case incrNow
//      case squareNow
//    }
//
//    let counterReducer = Reducer<Int, CounterAction, TestScheduler> {
//      state, action, scheduler in
//      switch action {
//      case .incrAndSquareLater:
//        return .merge(
//          Effect(value: .incrNow)
//            .delay(.seconds(2), scheduler: scheduler)
//            .eraseToEffect(),
//          Effect(value: .squareNow)
//            .delay(.seconds(1), scheduler: scheduler)
//            .eraseToEffect(),
//          Effect(value: .squareNow)
//            .delay(.seconds(2), scheduler: scheduler)
//            .eraseToEffect()
//        )
//      case .incrNow:
//        state += 1
//        return .none
//      case .squareNow:
//        state *= state
//        return .none
//      }
//    }
//
//    let scheduler: TestScheduler  = TestScheduler.default()
//
//    let store = TestStore(
//      initialState: 2,
//      reducer: counterReducer,
//      environment: scheduler
//    )
//
//    store.send(.incrAndSquareLater)
//    scheduler.advanceTo(1)
//    store.receive(.squareNow) { $0 = 4 }
//    scheduler.advanceTo(1)
//    store.receive(.incrNow) { $0 = 5 }
//    store.receive(.squareNow) { $0 = 25 }
//
//    store.send(.incrAndSquareLater)
//    scheduler.advanceTo(2)
//    store.receive(.squareNow) { $0 = 625 }
//    store.receive(.incrNow) { $0 = 626 }
//    store.receive(.squareNow) { $0 = 391876 }
//  }

//  func testSimultaneousWorkOrdering() {
//    let testScheduler = TestScheduler<
//      DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions
//    >(
//      now: .init(.init(uptimeNanoseconds: 1))
//    )
//
//    var values: [Int] = []
//    testScheduler.schedule(after: testScheduler.now, interval: 1) { values.append(1) }
//      .store(in: &self.cancellables)
//    testScheduler.schedule(after: testScheduler.now, interval: 2) { values.append(42) }
//      .store(in: &self.cancellables)
//
//    XCTAssertNoDifference(values, [])
//    testScheduler.advance()
//    XCTAssertNoDifference(values, [1, 42])
//    testScheduler.advance(by: 2)
//    XCTAssertNoDifference(values, [1, 42, 1, 1, 42])
//  }

  func testLongLivingEffects() {
    typealias Environment = (
      startEffect: Effect<Void>,
      stopEffect: Effect<Never>
    )

    enum Action { case end, incr, start }

    let reducer = Reducer<Int, Action, Environment> { state, action, environment in
      switch action {
      case .end:
        return environment.stopEffect.fireAndForget()
      case .incr:
        state += 1
        return .none
      case .start:
        return environment.startEffect.map { Action.incr }
      }
    }

    let subject = PublishSubject<Void>()

    let store = TestStore(
      initialState: 0,
      reducer: reducer,
      environment: (
        startEffect: subject.eraseToEffect(),
        stopEffect: .fireAndForget { subject.onCompleted() }
      )
    )

    store.send(.start)
    store.send(.incr) { $0 = 1 }
    subject.onNext(())
    store.receive(.incr) { $0 = 2 }
    store.send(.end)
  }

  func testCancellation() {
    enum Action: Equatable {
      case cancel
      case incr
      case response(Int)
    }

    struct Environment {
      let fetch: (Int) -> Effect<Int>
      let mainQueue: TestScheduler
    }

    let reducer = Reducer<Int, Action, Environment> { state, action, environment in
      struct CancelId: Hashable {}

      switch action {
      case .cancel:
        return .cancel(id: CancelId())

      case .incr:
        state += 1
        return environment.fetch(state)
          .observe(on: environment.mainQueue)
          .map(Action.response)
          .eraseToEffect()
          .cancellable(id: CancelId())

      case let .response(value):
        state = value
        return .none
      }
    }

    let scheduler = TestScheduler.default()

    let store = TestStore(
      initialState: 0,
      reducer: reducer,
      environment: Environment(
        fetch: { value in Effect(value: value * value) },
        mainQueue: scheduler
      )
    )

    store.send(.incr) { $0 = 1 }
    scheduler.advance()
    store.receive(.response(1)) { $0 = 1 }

    store.send(.incr) { $0 = 2 }
    store.send(.cancel)
    scheduler.run()
  }
}
