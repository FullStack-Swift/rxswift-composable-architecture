#if DEBUG
import Combine
import CustomDump
import Foundation
import XCTestDynamicOverlay

public final class TestStore<State, LocalState, Action, LocalAction, Environment> {
  public var environment: Environment
  
  private let file: StaticString
  private let fromLocalAction: (LocalAction) -> Action
  private var line: UInt
  private var longLivingEffects: Set<LongLivingEffect> = []
  private var receivedActions: [(action: Action, state: State)] = []
  private let reducer: Reducer<State, Action, Environment>
  private var snapshotState: State
  private var store: Store<State, TestAction>!
  private let toLocalState: (State) -> LocalState
  
  private init(
    environment: Environment,
    file: StaticString,
    fromLocalAction: @escaping (LocalAction) -> Action,
    initialState: State,
    line: UInt,
    reducer: Reducer<State, Action, Environment>,
    toLocalState: @escaping (State) -> LocalState
  ) {
    self.environment = environment
    self.file = file
    self.fromLocalAction = fromLocalAction
    self.line = line
    self.reducer = reducer
    self.snapshotState = initialState
    self.toLocalState = toLocalState
    
    self.store = Store(
      initialState: initialState,
      reducer: Reducer<State, TestAction, Void> { [unowned self] state, action, _ in
        let effects: Effect<Action>
        switch action.origin {
        case let .send(localAction):
          effects = self.reducer.run(&state, self.fromLocalAction(localAction), self.environment)
          self.snapshotState = state
          
        case let .receive(action):
          effects = self.reducer.run(&state, action, self.environment)
          self.receivedActions.append((action, state))
        }
        
        let effect = LongLivingEffect(file: action.file, line: action.line)
        return effects
          .do { [weak self] error in
            self?.longLivingEffects.remove(effect)
          } afterCompleted: { [weak self] in
            self?.longLivingEffects.remove(effect)
          } onSubscribed: { [weak self] in
            self?.longLivingEffects.insert(effect)
          } onDispose: { [weak self] in
            self?.longLivingEffects.remove(effect)
          }
          .map { .init(origin: .receive($0), file: action.file, line: action.line) }
          .eraseToEffect()
      },
      environment: ()
    )
  }
  
  deinit {
    self.completed()
  }
  
  private func completed() {
    if !self.receivedActions.isEmpty {
      var actions = ""
      customDump(self.receivedActions.map(\.action), to: &actions)
      XCTFail(
          """
          The store received \(self.receivedActions.count) unexpected \
          action\(self.receivedActions.count == 1 ? "" : "s") after this one: …
          
          Unhandled actions: \(actions)
          """,
          file: self.file, line: self.line
      )
    }
    for effect in self.longLivingEffects {
      XCTFail(
          """
          An effect returned for this action is still running. It must complete before the end of \
          the test. …
          
          To fix, inspect any effects the reducer returns for this action and ensure that all of \
          them complete by the end of the test. There are a few reasons why an effect may not have \
          completed:
          
          • If an effect uses a scheduler (via "receive(on:)", "delay", "debounce", etc.), make \
          sure that you wait enough time for the scheduler to perform the effect. If you are using \
          a test scheduler, advance the scheduler so that the effects may complete, or consider \
          using an immediate scheduler to immediately perform the effect instead.
          
          • If you are returning a long-living effect (timers, notifications, subjects, etc.), \
          then make sure those effects are torn down by marking the effect ".cancellable" and \
          returning a corresponding cancellation effect ("Effect.cancel") from another action, or, \
          if your effect is driven by a Combine subject, send it a completion.
          """,
          file: effect.file,
          line: effect.line
      )
    }
  }
  
  private struct LongLivingEffect: Hashable {
    let id = UUID()
    let file: StaticString
    let line: UInt
    
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
      self.id.hash(into: &hasher)
    }
  }
}

extension TestStore where State == LocalState, Action == LocalAction {
  public convenience init(
    initialState: State,
    reducer: Reducer<State, Action, Environment>,
    environment: Environment,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.init(
      environment: environment,
      file: file,
      fromLocalAction: { $0 },
      initialState: initialState,
      line: line,
      reducer: reducer,
      toLocalState: { $0 }
    )
  }
}

extension TestStore where LocalState: Equatable {
  public func send(
    _ action: LocalAction,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout LocalState) throws -> Void = { _ in }
  ) {
    if !self.receivedActions.isEmpty {
      var actions = ""
      customDump(self.receivedActions.map(\.action), to: &actions)
      XCTFail(
          """
          Must handle \(self.receivedActions.count) received \
          action\(self.receivedActions.count == 1 ? "" : "s") before sending an action: …
          
          Unhandled actions: \(actions)
          """,
          file: file, line: line
      )
    }
    var expectedState = self.toLocalState(self.snapshotState)
    ViewStore(
      self.store.scope(
        state: self.toLocalState,
        action: { .init(origin: .send($0), file: file, line: line) }
      )
    )
      .send(action)
    do {
      try update(&expectedState)
    } catch {
      XCTFail("Threw error: \(error)", file: file, line: line)
    }
    self.expectedStateShouldMatch(
      expected: expectedState,
      actual: self.toLocalState(self.snapshotState),
      file: file,
      line: line
    )
    if "\(self.file)" == "\(file)" {
      self.line = line
    }
  }
  
  private func expectedStateShouldMatch(
    expected: LocalState,
    actual: LocalState,
    file: StaticString,
    line: UInt
  ) {
    if expected != actual {
      let difference =
      diff(expected, actual, format: .proportional)
        .map { "\($0.indent(by: 4))\n\n(Expected: −, Actual: +)" }
      ?? """
          Expected:
          \(String(describing: expected).indent(by: 2))
          
          Actual:
          \(String(describing: actual).indent(by: 2))
          """
      
      XCTFail(
          """
          State change does not match expectation: …
          
          \(difference)
          """,
          file: file,
          line: line
      )
    }
  }
}

extension TestStore where LocalState: Equatable, Action: Equatable {
  public func receive(
    _ expectedAction: Action,
    file: StaticString = #file,
    line: UInt = #line,
    _ update: @escaping (inout LocalState) throws -> Void = { _ in }
  ) {
    guard !self.receivedActions.isEmpty else {
      XCTFail(
          """
          Expected to receive an action, but received none.
          """,
          file: file, line: line
      )
      return
    }
    let (receivedAction, state) = self.receivedActions.removeFirst()
    if expectedAction != receivedAction {
      let difference =
      diff(expectedAction, receivedAction, format: .proportional)
        .map { "\($0.indent(by: 4))\n\n(Expected: −, Received: +)" }
      ?? """
          Expected:
          \(String(describing: expectedAction).indent(by: 2))
          
          Received:
          \(String(describing: receivedAction).indent(by: 2))
          """
      
      XCTFail(
          """
          Received unexpected action: …
          
          \(difference)
          """,
          file: file, line: line
      )
    }
    var expectedState = self.toLocalState(self.snapshotState)
    do {
      try update(&expectedState)
    } catch {
      XCTFail("Threw error: \(error)", file: file, line: line)
    }
    expectedStateShouldMatch(
      expected: expectedState,
      actual: self.toLocalState(state),
      file: file,
      line: line
    )
    snapshotState = state
    if "\(self.file)" == "\(file)" {
      self.line = line
    }
  }
  
  /// Asserts against a script of actions.
  public func assert(
    _ steps: Step...,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    assert(steps, file: file, line: line)
  }
  
  /// Asserts against an array of actions.
  public func assert(
    _ steps: [Step],
    file: StaticString = #file,
    line: UInt = #line
  ) {
    
    func assert(step: Step) {
      switch step.type {
      case let .send(action, update):
        self.send(action, file: step.file, line: step.line, update)
        
      case let .receive(expectedAction, update):
        self.receive(expectedAction, file: step.file, line: step.line, update)
        
      case let .environment(work):
        if !self.receivedActions.isEmpty {
          var actions = ""
          customDump(self.receivedActions.map(\.action), to: &actions)
          XCTFail(
              """
              Must handle \(self.receivedActions.count) received \
              action\(self.receivedActions.count == 1 ? "" : "s") before performing this work: …
              
              Unhandled actions: \(actions)
              """,
              file: step.file, line: step.line
          )
        }
        do {
          try work(&self.environment)
        } catch {
          XCTFail("Threw error: \(error)", file: step.file, line: step.line)
        }
        
      case let .do(work):
        if !receivedActions.isEmpty {
          var actions = ""
          customDump(self.receivedActions.map(\.action), to: &actions)
          XCTFail(
              """
              Must handle \(self.receivedActions.count) received \
              action\(self.receivedActions.count == 1 ? "" : "s") before performing this work: …
              
              Unhandled actions: \(actions)
              """,
              file: step.file, line: step.line
          )
        }
        do {
          try work()
        } catch {
          XCTFail("Threw error: \(error)", file: step.file, line: step.line)
        }
        
      case let .sequence(subSteps):
        subSteps.forEach(assert(step:))
      }
    }
    
    steps.forEach(assert(step:))
    
    self.completed()
  }
}

extension TestStore {
  public func scope<S, A>(
    state toLocalState: @escaping (LocalState) -> S,
    action fromLocalAction: @escaping (A) -> LocalAction
  ) -> TestStore<State, S, Action, A, Environment> {
    .init(
      environment: self.environment,
      file: self.file,
      fromLocalAction: { self.fromLocalAction(fromLocalAction($0)) },
      initialState: self.store.state.value,
      line: self.line,
      reducer: self.reducer,
      toLocalState: { toLocalState(self.toLocalState($0)) }
    )
  }
  
  public func scope<S>(
    state toLocalState: @escaping (LocalState) -> S
  ) -> TestStore<State, S, Action, LocalAction, Environment> {
    self.scope(state: toLocalState, action: { $0 })
  }
  
  /// A single step of a ``TestStore`` assertion.
  public struct Step {
    fileprivate let type: StepType
    fileprivate let file: StaticString
    fileprivate let line: UInt
    
    private init(
      _ type: StepType,
      file: StaticString = #file,
      line: UInt = #line
    ) {
      self.type = type
      self.file = file
      self.line = line
    }
    
    public static func send(
      _ action: LocalAction,
      file: StaticString = #file,
      line: UInt = #line,
      _ update: @escaping (inout LocalState) throws -> Void = { _ in }
    ) -> Step {
      Step(.send(action, update), file: file, line: line)
    }
    
    public static func receive(
      _ action: Action,
      file: StaticString = #file,
      line: UInt = #line,
      _ update: @escaping (inout LocalState) throws -> Void = { _ in }
    ) -> Step {
      Step(.receive(action, update), file: file, line: line)
    }
    
    public static func environment(
      file: StaticString = #file,
      line: UInt = #line,
      _ update: @escaping (inout Environment) throws -> Void
    ) -> Step {
      Step(.environment(update), file: file, line: line)
    }
    
    public static func `do`(
      file: StaticString = #file,
      line: UInt = #line,
      _ work: @escaping () throws -> Void
    ) -> Step {
      Step(.do(work), file: file, line: line)
    }
    
    public static func sequence(
      _ steps: [Step],
      file: StaticString = #file,
      line: UInt = #line
    ) -> Step {
      Step(.sequence(steps), file: file, line: line)
    }
    
    public static func sequence(
      _ steps: Step...,
      file: StaticString = #file,
      line: UInt = #line
    ) -> Step {
      Step(.sequence(steps), file: file, line: line)
    }
    
    fileprivate indirect enum StepType {
      case send(LocalAction, (inout LocalState) throws -> Void)
      case receive(Action, (inout LocalState) throws -> Void)
      case environment((inout Environment) throws -> Void)
      case `do`(() throws -> Void)
      case sequence([Step])
    }
  }
  
  private struct TestAction {
    let origin: Origin
    let file: StaticString
    let line: UInt
    
    enum Origin {
      case send(LocalAction)
      case receive(Action)
    }
  }
}
#endif
