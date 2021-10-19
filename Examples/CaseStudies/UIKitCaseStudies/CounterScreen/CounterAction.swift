import ComposableArchitecture
import Foundation

enum CounterAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case decrementButtonTapped
  case incrementButtonTapped
}
