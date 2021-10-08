import ComposableArchitecture
import Foundation

struct CountersTableState: Equatable {
  var counters: [CounterState] = [CounterState(),
                                  CounterState(),
                                  CounterState(),
                                  CounterState(),
                                  CounterState()]
}
