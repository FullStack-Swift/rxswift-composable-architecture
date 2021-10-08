import ComposableArchitecture
import Foundation

let AuthReducer = Reducer<AuthState, AuthAction, AuthEnvironment>.combine(
  
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
