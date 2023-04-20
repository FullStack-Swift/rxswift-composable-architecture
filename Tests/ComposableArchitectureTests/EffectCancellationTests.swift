//import RxSwift
//@_spi(Internals) import ComposableArchitecture
//import XCTest
//
//final class EffectCancellationTests: BaseTCATestCase {
//  struct CancelID: Hashable {}
//  var cancellables: Set<AnyDisposable> = []
//
//  override func tearDown() {
//    super.tearDown()
//    self.cancellables.removeAll()
//  }
//
//  func testCancellation() {
//    var values: [Int] = []
//
//    let subject = PublishSubject<Int>()
//    let effect = EffectPublisher<Int,Never>(subject)
//      .cancellable(id: CancelID())
//
//    effect
//      .sink { values.append($0) }
//      .store(in: &cancellables)
//
//    XCTAssertEqual(values, [])
//    subject.send(1)
//    XCTAssertEqual(values, [1])
//    subject.send(2)
//    XCTAssertEqual(values, [1, 2])
//
//    EffectTask<Never>.cancel(id: CancelID())
//      .sink { _ in }
//      .store(in: &self.cancellables)
//
//    subject.send(3)
//    XCTAssertEqual(values, [1, 2])
//  }
//
//  func testCancelInFlight() {
//    var values: [Int] = []
//
//    let subject = PublishSubject<Int>()
//    EffectPublisher<Int, Never>(subject)
//      .cancellable(id: CancelID(), cancelInFlight: true)
//      .sink { values.append($0) }
//      .store(in: &self.cancellables)
//
//    XCTAssertEqual(values, [])
//    subject.send(1)
//    XCTAssertEqual(values, [1])
//    subject.send(2)
//    XCTAssertEqual(values, [1, 2])
//
//    defer { Task.cancel(id: CancelID()) }
//    EffectPublisher<Int, Never>(subject)
//      .cancellable(id: CancelID(), cancelInFlight: true)
//      .sink { values.append($0) }
//      .store(in: &self.cancellables)
//
//    subject.send(3)
//    XCTAssertEqual(values, [1, 2, 3])
//    subject.send(4)
//    XCTAssertEqual(values, [1, 2, 3, 4])
//  }
//
//  func testCancellationAfterDelay() {
//    var value: Int?
//
//    Observable.just(1)
//      .delay(.microseconds(150), scheduler: MainScheduler())
//      .eraseToEffect()
//      .cancellable(id: CancelID())
//      .sink { value = $0 }
//      .store(in: &self.cancellables)
//
//    XCTAssertEqual(value, nil)
//
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//      EffectTask<Never>.cancel(id: CancelID())
//        .sink { _ in }
//        .store(in: &self.cancellables)
//    }
//
//    _ = XCTWaiter.wait(for: [self.expectation(description: "")], timeout: 1)
//    XCTAssertEqual(value, nil)
//  }
//
//  func testCancellationAfterDelay_WithTestScheduler() {
//    let mainQueue = DispatchQueue.test
//    var value: Int?
//
//    Observable.just(1)
//      .delay(.seconds(2), scheduler: MainScheduler())
//      .eraseToEffect()
//      .cancellable(id: CancelID())
//      .sink { value = $0 }
//      .store(in: &self.cancellables)
//
//    XCTAssertEqual(value, nil)
//
//    mainQueue.advance(by: 1)
//    EffectTask<Never>.cancel(id: CancelID())
//      .sink { _ in }
//      .store(in: &self.cancellables)
//
//    mainQueue.run()
//
//    XCTAssertEqual(value, nil)
//  }
//
//  func testCancellablesCleanUp_OnComplete() {
//    let id = UUID()
//
//    Observable.just(1)
//      .eraseToEffect()
//      .cancellable(id: id)
//      .sink(receiveValue: { _ in })
//      .store(in: &self.cancellables)
//
//    XCTAssertEqual(_cancellationCancellables.exists(at: id), false)
//  }
//
//  func testCancellablesCleanUp_OnCancel() {
//    let id = UUID()
//
//    let mainQueue = DispatchQueue.test
//    Observable.just(1)
//      .delay(.seconds(1), scheduler: MainScheduler())
//      .eraseToEffect()
//      .cancellable(id: id)
//      .sink(receiveValue: { _ in })
//      .store(in: &self.cancellables)
//
//    EffectPublisher<Int, Never>.cancel(id: id)
//      .sink(receiveValue: { _ in })
//      .store(in: &self.cancellables)
//
//    XCTAssertEqual(_cancellationCancellables.exists(at: id), false)
//  }
//
//  func testDoubleCancellation() {
//    var values: [Int] = []
//
//    let subject = PublishSubject<Int>()
//    let effect = EffectPublisher<Int, Never>(subject)
//      .cancellable(id: CancelID())
//      .cancellable(id: CancelID())
//
//    effect
//      .sink { values.append($0) }
//      .store(in: &self.cancellables)
//
//    XCTAssertEqual(values, [])
//    subject.send(1)
//    XCTAssertEqual(values, [1])
//
//    EffectTask<Never>.cancel(id: CancelID())
//      .sink { _ in }
//      .store(in: &self.cancellables)
//
//    subject.send(2)
//    XCTAssertEqual(values, [1])
//  }
//
//  func testCompleteBeforeCancellation() {
//    var values: [Int] = []
//
//    let subject = PublishSubject<Int>()
//    let effect = EffectPublisher<Int, Never>(subject)
//      .cancellable(id: CancelID())
//
//    effect
//      .sink { values.append($0) }
//      .store(in: &self.cancellables)
//
//    subject.send(1)
//    XCTAssertEqual(values, [1])
//
//    subject.send(completion: .finished)
//    XCTAssertEqual(values, [1])
//
//    EffectTask<Never>.cancel(id: CancelID())
//      .sink { _ in }
//      .store(in: &self.cancellables)
//
//    XCTAssertEqual(values, [1])
//  }
//
//  func testConcurrentCancels() {
//    let queues = [
//      DispatchQueue.main,
//      DispatchQueue.global(qos: .background),
//      DispatchQueue.global(qos: .default),
//      DispatchQueue.global(qos: .unspecified),
//      DispatchQueue.global(qos: .userInitiated),
//      DispatchQueue.global(qos: .userInteractive),
//      DispatchQueue.global(qos: .utility),
//    ]
//    let ids = (1...10).map { _ in UUID() }
//
//    let effect = EffectPublisher.merge(
//      (1...1_000).map { idx -> EffectPublisher<Int, Never> in
//        let id = ids[idx % 10]
//
//        return EffectPublisher.merge(
//          Just(idx)
//            .delay(
//              for: .milliseconds(Int.random(in: 1...100)), scheduler: queues.randomElement()!
//            )
//            .eraseToEffect()
//            .cancellable(id: id),
//
//          Just(())
//            .delay(
//              for: .milliseconds(Int.random(in: 1...100)), scheduler: queues.randomElement()!
//            )
//            .flatMap { EffectPublisher.cancel(id: id) }
//            .eraseToEffect()
//        )
//      }
//    )
//
//    let expectation = self.expectation(description: "wait")
//    effect
//      .sink(receiveCompletion: { _ in expectation.fulfill() }, receiveValue: { _ in })
//      .store(in: &self.cancellables)
//    self.wait(for: [expectation], timeout: 999)
//
//    for id in ids {
//      XCTAssertEqual(
//        _cancellationCancellables.exists(at: id),
//        false,
//        "cancellationCancellables should not contain id \(id)"
//      )
//    }
//  }
//
//  func testNestedCancels() {
//    let id = UUID()
//
//    var effect = Observable<Void>.empty()
//      .eraseToEffect()
//      .cancellable(id: id)
//
//    for _ in 1...1_000 {
//      effect = effect.cancellable(id: id)
//    }
//
//    effect
//      .sink(receiveValue: { _ in })
//      .store(in: &cancellables)
//
//    cancellables.removeAll()
//
//    XCTAssertEqual(_cancellationCancellables.exists(at: id), false)
//  }
//
//  func testSharedId() {
//    let mainQueue = DispatchQueue.test
//
//    let effect1 = Observable.just(1)
//      .delay(for: 1, scheduler: mainQueue)
//      .eraseToEffect()
//      .cancellable(id: "id")
//
//    let effect2 = Observable.just(1)
//      .delay(for: 2, scheduler: mainQueue)
//      .eraseToEffect()
//      .cancellable(id: "id")
//
//    var expectedOutput: [Int] = []
//    effect1
//      .sink { expectedOutput.append($0) }
//      .store(in: &cancellables)
//    effect2
//      .sink { expectedOutput.append($0) }
//      .store(in: &cancellables)
//
//    XCTAssertEqual(expectedOutput, [])
//    mainQueue.advance(by: 1)
//    XCTAssertEqual(expectedOutput, [1])
//    mainQueue.advance(by: 1)
//    XCTAssertEqual(expectedOutput, [1, 2])
//  }
//
//  func testImmediateCancellation() {
//    let mainQueue = DispatchQueue.test
//
//    var expectedOutput: [Int] = []
//    // Don't hold onto cancellable so that it is deallocated immediately.
//    _ = Deferred { Just(1) }
//      .delay(for: 1, scheduler: mainQueue)
//      .eraseToEffect()
//      .cancellable(id: "id")
//      .sink { expectedOutput.append($0) }
//
//    XCTAssertEqual(expectedOutput, [])
//    mainQueue.advance(by: 1)
//    XCTAssertEqual(expectedOutput, [])
//  }
//
//  func testNestedMergeCancellation() {
//    let effect = EffectPublisher<Int, Never>.merge(
//      (1...2).publisher
//        .asObservable()
//        .eraseToEffect()
//        .cancellable(id: 1)
//    )
//      .cancellable(id: 2)
//
//    var output: [Int] = []
//    effect
//      .sink { output.append($0) }
//      .store(in: &cancellables)
//
//    XCTAssertEqual(output, [1, 2])
//  }
//
//  func testMultipleCancellations() {
//    let mainQueue = DispatchQueue.test
//    var output: [AnyHashable] = []
//
//    struct A: Hashable {}
//    struct B: Hashable {}
//    struct C: Hashable {}
//
//    let ids: [AnyHashable] = [A(), B(), C()]
//    let effects = ids.map { id in
//      Observable.just(id)
//        .delay(for: 1, scheduler: mainQueue)
//        .eraseToEffect()
//        .cancellable(id: id)
//    }
//
//    EffectTask<AnyHashable>.merge(effects)
//      .sink { output.append($0) }
//      .store(in: &self.cancellables)
//
//    EffectTask<AnyHashable>
//      .cancel(ids: [A(), C()])
//      .sink { _ in }
//      .store(in: &self.cancellables)
//
//    mainQueue.advance(by: 1)
//    XCTAssertEqual(output, [B()])
//  }
//
//  func testCancelIDHash() {
//    struct CancelID1: Hashable {}
//    struct CancelID2: Hashable {}
//    let id1 = _CancelID(id: CancelID1())
//    let id2 = _CancelID(id: CancelID2())
//    XCTAssertNotEqual(id1, id2)
//    // NB: We hash the type of the cancel ID to give more variance in the hash since all empty
//    //     structs in Swift have the same hash value.
//    XCTAssertNotEqual(id1.hashValue, id2.hashValue)
//  }
//}
//
