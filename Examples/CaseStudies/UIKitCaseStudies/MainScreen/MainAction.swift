import ComposableArchitecture
import Foundation

enum MainAction: Equatable {
  case changRootScreen(RootScreen)
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case logout
}
