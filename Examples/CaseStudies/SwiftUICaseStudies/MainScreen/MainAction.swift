import ComposableArchitecture
import Foundation

enum MainAction: Equatable {
  case viewOnAppear
  case viewOnDisappear
  case none
  case changeRootScreen(RootScreen)
}
