import ComposableArchitecture
import Foundation

let MainReducer = Reducer<MainState, MainAction, MainEnvironment>.combine(
  Reducer { state, action, environment in
    switch action {
    case .viewOnAppear:
      break
    case .viewOnDisappear:
      break
    default:
      break
    }
    return .none
  }
)
  .debug()
