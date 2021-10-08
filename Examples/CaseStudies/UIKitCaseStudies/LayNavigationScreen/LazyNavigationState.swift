import ComposableArchitecture
import Foundation

struct LazyNavigationState: Equatable {
  var optionalCounter: CounterState?
  var isActivityIndicatorHidden = true
}
