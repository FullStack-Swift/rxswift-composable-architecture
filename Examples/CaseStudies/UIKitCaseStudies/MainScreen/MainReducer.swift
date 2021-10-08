import ComposableArchitecture
import Foundation

let MainReducer = Reducer<MainState, MainAction, MainEnvironment>.combine(
  Reducer { state, action, enviroment in
    switch action {
    case .viewDidLoad:
      break
    case .viewWillAppear:
      break
    case .viewWillDisappear:
      break
    case .logout:
      return Effect(value: MainAction.changRootScreen(.auth))
    default:
      break
    }
    return .none
  }
)
  .debug()
