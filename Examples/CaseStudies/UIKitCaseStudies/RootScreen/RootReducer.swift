import ComposableArchitecture
import Foundation

let RootReducer = Reducer<RootState, RootAction, RootEnvironment>.combine(
  AuthReducer.pullback(state: \.authState, action: /RootAction.authAction, environment: { _ in
      .init()
  }),
  MainReducer.pullback(state: \.mainState, action: /RootAction.mainAction, environment: { _ in
      .init()
  }),
  Reducer { state, action, enviroment in
    switch action {
    case .authAction(.changeRootScreen(let screen)):
      state.rootScreen = screen
    case .mainAction(.changRootScreen(let screen)):
      state.rootScreen = screen
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
