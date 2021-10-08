import ComposableArchitecture
import Foundation

let CounterReducer = Reducer<CounterState, CounterAction, CounterEnvironment>.combine(
  Reducer { state, action, enviroment in
    switch action {
    case .viewDidLoad:
      break
    case .viewWillAppear:
      break
    case .viewWillDisappear:
      break
    case .decrementButtonTapped:
      state.count -= 1
      return .none
    case .incrementButtonTapped:
      state.count += 1
      return .none
    default:
      break
    }
    return .none
  }
)
  .debug()
