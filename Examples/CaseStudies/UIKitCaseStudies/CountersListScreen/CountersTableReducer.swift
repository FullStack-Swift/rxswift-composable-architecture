import ComposableArchitecture
import Foundation

let CountersTableReducer = Reducer<CountersTableState, CountersTableAction, CountersTableEnvironment>.combine(
  CounterReducer.forEach(state: \.counters, action: /CountersTableAction.counter(index:action:), environment: { _ in
      .init()
  }),
  Reducer { state, action, enviroment in
    switch action {
    case .viewDidLoad:
      break
    case .viewWillAppear:
      break
    case .viewWillDisappear:
      break
    default:
      break
    }
    return .none
  }
)
  .debug()
