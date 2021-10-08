import ComposableArchitecture
import Foundation

enum AuthAction: Equatable {
  case viewOnAppear
  case viewOnDisappear
  case none
  case changeRootScreen(RootScreen)
}
