import ComposableArchitecture
import Foundation

struct EagerNavigationState: Equatable {
  var isNavigationActive = false
  var optionalCounter: CounterState?
}
