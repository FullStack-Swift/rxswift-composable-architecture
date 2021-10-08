import ComposableArchitecture
import Foundation

enum CountersTableAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case counter(index: Int, action: CounterAction)
}
