import CasePaths
import Dispatch

public enum ActionFormat {
  case labelsOnly
  case prettyPrint
}

extension Reducer {
  public func debug(
    _ prefix: String = "",
    actionFormat: ActionFormat = .prettyPrint,
    environment toDebugEnvironment: @escaping (Environment) -> DebugEnvironment = { _ in
      DebugEnvironment()
    }
  ) -> Reducer {
    self.debug(
      prefix,
      state: { $0 },
      action: .self,
      actionFormat: actionFormat,
      environment: toDebugEnvironment
    )
  }
  
  public func debugActions(
    _ prefix: String = "",
    actionFormat: ActionFormat = .prettyPrint,
    environment toDebugEnvironment: @escaping (Environment) -> DebugEnvironment = { _ in
      DebugEnvironment()
    }
  ) -> Reducer {
    self.debug(
      prefix,
      state: { _ in () },
      action: .self,
      actionFormat: actionFormat,
      environment: toDebugEnvironment
    )
  }
  
  public func debug<LocalState, LocalAction>(
    _ prefix: String = "",
    state toLocalState: @escaping (State) -> LocalState,
    action toLocalAction: CasePath<Action, LocalAction>,
    actionFormat: ActionFormat = .prettyPrint,
    environment toDebugEnvironment: @escaping (Environment) -> DebugEnvironment = { _ in
      DebugEnvironment()
    }
  ) -> Reducer {
#if DEBUG
    return .init { state, action, environment in
      let previousState = toLocalState(state)
      let effects = self.run(&state, action, environment)
      guard let localAction = toLocalAction.extract(from: action) else { return effects }
      let nextState = toLocalState(state)
      let debugEnvironment = toDebugEnvironment(environment)
      return .merge(
        .fireAndForget {
          debugEnvironment.queue.async {
            var actionOutput = ""
            if actionFormat == .prettyPrint {
              customDump(localAction, to: &actionOutput, indent: 2)
            } else {
              actionOutput.write(debugCaseOutput(localAction).indent(by: 2))
            }
            let stateOutput =
            LocalState.self == Void.self
            ? ""
            : diff(previousState, nextState).map { "\($0)\n" } ?? "  (No state changes)\n"
            debugEnvironment.printer(
                """
                \(prefix.isEmpty ? "" : "\(prefix): ")received action:
                \(actionOutput)
                \(stateOutput)
                """
            )
          }
        },
        effects
      )
    }
#else
    return self
#endif
  }
}

public struct DebugEnvironment {
  public var printer: (String) -> Void
  public var queue: DispatchQueue
  
  public init(
    printer: @escaping (String) -> Void = { print($0) },
    queue: DispatchQueue
  ) {
    self.printer = printer
    self.queue = queue
  }
  
  public init(
    printer: @escaping (String) -> Void = { print($0) }
  ) {
    self.init(printer: printer, queue: _queue)
  }
}

private let _queue = DispatchQueue(
  label: "ComposableArchitecture.DebugEnvironment",
  qos: .background
)
