import CasePaths
import RxSwift

public struct Reducer<State, Action, Environment> {
  private let reducer: (inout State, Action, Environment) -> Effect<Action>
  
  public init(_ reducer: @escaping (inout State, Action, Environment) -> Effect<Action>) {
    self.reducer = reducer
  }
  
  public static var empty: Reducer {
    Self { _, _, _ in .none }
  }
  
  public static func combine(_ reducers: Reducer...) -> Reducer {
    .combine(reducers)
  }
  
  public static func combine(_ reducers: [Reducer]) -> Reducer {
    Self { value, action, environment in
        .merge(reducers.map { $0.reducer(&value, action, environment) })
    }
  }
  
  public func combined(with other: Reducer) -> Reducer {
    .combine(self, other)
  }
  
  public func pullback<GlobalState, GlobalAction, GlobalEnvironment>(
    state toLocalState: WritableKeyPath<GlobalState, State>,
    action toLocalAction: CasePath<GlobalAction, Action>,
    environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
  ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
    .init { globalState, globalAction, globalEnvironment in
      guard let localAction = toLocalAction.extract(from: globalAction) else { return .none }
      return self.reducer(
        &globalState[keyPath: toLocalState],
        localAction,
        toLocalEnvironment(globalEnvironment)
      )
        .map(toLocalAction.embed)
    }
  }
  
  public func pullback<GlobalState, GlobalAction, GlobalEnvironment>(
    state toLocalState: CasePath<GlobalState, State>,
    action toLocalAction: CasePath<GlobalAction, Action>,
    environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment,
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
    .init { globalState, globalAction, globalEnvironment in
      guard let localAction = toLocalAction.extract(from: globalAction) else { return .none }
      
      guard var localState = toLocalState.extract(from: globalState) else {
        if breakpointOnNil {
          breakpoint(
            """
            ---
            Warning: Reducer.pullback@\(file):\(line)
            
            "\(debugCaseOutput(localAction))" was received by a reducer when its state was \
            unavailable. This is generally considered an application logic error, and can happen \
            for a few reasons:
            
            * The reducer for a particular case of state was combined with or run from another \
            reducer that set "\(State.self)" to another case before the reducer ran. Combine or \
            run case-specific reducers before reducers that may set their state to another case. \
            This ensures that case-specific reducers can handle their actions while their state \
            is available.
            
            * An in-flight effect emitted this action when state was unavailable. While it may be \
            perfectly reasonable to ignore this action, you may want to cancel the associated \
            effect before state is set to another case, especially if it is a long-living effect.
            
            * This action was sent to the store while state was another case. Make sure that \
            actions for this reducer can only be sent to a view store when state is non-"nil". \
            In SwiftUI applications, use "SwitchStore".
            ---
            """
          )
        }
        return .none
      }
      defer { globalState = toLocalState.embed(localState) }
      let effects = self.run(
        &localState,
        localAction,
        toLocalEnvironment(globalEnvironment)
      )
        .map(toLocalAction.embed)
      return effects
    }
  }
  
  public func optional(
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<
    State?, Action, Environment
  > {
    .init { state, action, environment in
      guard state != nil else {
        if breakpointOnNil {
          breakpoint(
            """
            ---
            Warning: Reducer.optional@\(file):\(line)
            
            "\(debugCaseOutput(action))" was received by an optional reducer when its state was \
            "nil". This is generally considered an application logic error, and can happen for a \
            few reasons:
            
            * The optional reducer was combined with or run from another reducer that set \
            "\(State.self)" to "nil" before the optional reducer ran. Combine or run optional \
            reducers before reducers that can set their state to "nil". This ensures that optional \
            reducers can handle their actions while their state is still non-"nil".
            
            * An in-flight effect emitted this action while state was "nil". While it may be \
            perfectly reasonable to ignore this action, you may want to cancel the associated \
            effect before state is set to "nil", especially if it is a long-living effect.
            
            * This action was sent to the store while state was "nil". Make sure that actions for \
            this reducer can only be sent to a view store when state is non-"nil". In SwiftUI \
            applications, use "IfLetStore".
            ---
            """
          )
        }
        return .none
      }
      return self.reducer(&state!, action, environment)
    }
  }
  
  public func forEach<GlobalState, GlobalAction, GlobalEnvironment, ID>(
    state toLocalState: WritableKeyPath<GlobalState, IdentifiedArray<ID, State>>,
    action toLocalAction: CasePath<GlobalAction, (ID, Action)>,
    environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment,
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
    .init { globalState, globalAction, globalEnvironment in
      guard let (id, localAction) = toLocalAction.extract(from: globalAction) else { return .none }
      if globalState[keyPath: toLocalState][id: id] == nil {
        if breakpointOnNil {
          breakpoint(
            """
            ---
            Warning: Reducer.forEach@\(file):\(line)
            
            "\(debugCaseOutput(localAction))" was received by a "forEach" reducer at id \(id) when \
            its state contained no element at this id. This is generally considered an application \
            logic error, and can happen for a few reasons:
            
            * This "forEach" reducer was combined with or run from another reducer that removed \
            the element at this id when it handled this action. To fix this make sure that this \
            "forEach" reducer is run before any other reducers that can move or remove elements \
            from state. This ensures that "forEach" reducers can handle their actions for the \
            element at the intended id.
            
            * An in-flight effect emitted this action while state contained no element at this id. \
            It may be perfectly reasonable to ignore this action, but you also may want to cancel \
            the effect it originated from when removing an element from the identified array, \
            especially if it is a long-living effect.
            
            * This action was sent to the store while its state contained no element at this id. \
            To fix this make sure that actions for this reducer can only be sent to a view store \
            when its state contains an element at this id. In SwiftUI applications, use \
            "ForEachStore".
            ---
            """
          )
        }
        return .none
      }
      return self.reducer(
          &globalState[keyPath: toLocalState][id: id]!,
          localAction,
          toLocalEnvironment(globalEnvironment)
        )
        .map { toLocalAction.embed((id, $0)) }
    }
  }
  
  public func forEach<GlobalState, GlobalAction, GlobalEnvironment, Key>(
    state toLocalState: WritableKeyPath<GlobalState, [Key: State]>,
    action toLocalAction: CasePath<GlobalAction, (Key, Action)>,
    environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment,
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
    .init { globalState, globalAction, globalEnvironment in
      guard let (key, localAction) = toLocalAction.extract(from: globalAction) else { return .none }
      
      if globalState[keyPath: toLocalState][key] == nil {
        if breakpointOnNil {
          breakpoint(
            """
            ---
            Warning: Reducer.forEach@\(file):\(line)
            
            "\(debugCaseOutput(localAction))" was received by a "forEach" reducer at key \(key) \
            when its state contained no element at this key. This is generally considered an \
            application logic error, and can happen for a few reasons:
            
            * This "forEach" reducer was combined with or run from another reducer that removed \
            the element at this key when it handled this action. To fix this make sure that this \
            "forEach" reducer is run before any other reducers that can move or remove elements \
            from state. This ensures that "forEach" reducers can handle their actions for the \
            element at the intended key.
            
            * An in-flight effect emitted this action while state contained no element at this \
            key. It may be perfectly reasonable to ignore this action, but you also may want to \
            cancel the effect it originated from when removing a value from the dictionary, \
            especially if it is a long-living effect.
            
            * This action was sent to the store while its state contained no element at this \
            key. To fix this make sure that actions for this reducer can only be sent to a view \
            store when its state contains an element at this key.
            ---
            """
          )
        }
        return .none
      }
      return self.reducer(
        &globalState[keyPath: toLocalState][key]!,
        localAction,
        toLocalEnvironment(globalEnvironment)
      )
        .map { toLocalAction.embed((key, $0)) }
    }
  }
  
  
  public func run(
    _ state: inout State,
    _ action: Action,
    _ environment: Environment
  ) -> Effect<Action> {
    self.reducer(&state, action, environment)
  }
  
  public func callAsFunction(
    _ state: inout State,
    _ action: Action,
    _ environment: Environment
  ) -> Effect<Action> {
    self.reducer(&state, action, environment)
  }
}
