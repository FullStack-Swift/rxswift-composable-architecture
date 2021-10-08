import ComposableArchitecture
import Foundation

enum LazyNavigationAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case optionalCounter(CounterAction)
  case setNavigation(isActive: Bool)
  case setNavigationIsActiveDelayCompleted
}
