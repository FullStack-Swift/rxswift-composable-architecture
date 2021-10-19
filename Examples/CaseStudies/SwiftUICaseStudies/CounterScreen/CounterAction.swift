import ComposableArchitecture
import Foundation

enum CounterAction: Equatable {
  case viewOnAppear
  case viewOnDisappear
  case none
  case decrement
  case increment
}
