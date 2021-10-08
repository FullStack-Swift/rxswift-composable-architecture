import ComposableArchitecture
import SwiftUI

struct CounterView: View {
  
  private let store: Store<CounterState, CounterAction>
  
  @ObservedObject
  private var viewStore: ViewStore<ViewState, ViewAction>
  
  init(store: Store<CounterState, CounterAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: CounterState(), reducer: CounterReducer, environment: CounterEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: CounterAction.init))
  }
  
  var body: some View {
    ZStack {
      HStack {
        Button("+") {
          viewStore.send(.increment)
        }
        Text(viewStore.countString)
        Button("-") {
          viewStore.send(.decrement)
        }
      }
    }
    .onAppear {
      viewStore.send(.viewOnAppear)
    }
    .onDisappear {
      viewStore.send(.viewOnDisappear)
    }
  }
}

struct CounterView_Previews: PreviewProvider {
  static var previews: some View {
    CounterView()
  }
}

fileprivate struct ViewState: Equatable {
  var countString: String
  init(state: CounterState) {
    self.countString = state.count.description
  }
}

fileprivate enum ViewAction: Equatable {
  case viewOnAppear
  case viewOnDisappear
  case none
  case decrement
  case increment
  
  init(action: CounterAction) {
    switch action {
    case .viewOnAppear:
      self = .viewOnAppear
    case .viewOnDisappear:
      self = .viewOnDisappear
    default:
      self = .none
    }
  }
}

fileprivate extension CounterState {
  var viewState: ViewState {
    get {
      ViewState(state: self)
    }
    set {
      
    }
  }
}

fileprivate extension CounterAction {
  init(action: ViewAction) {
    switch action {
    case .viewOnAppear:
      self = .viewOnAppear
    case .viewOnDisappear:
      self = .viewOnDisappear
    case .decrement:
      self = .decrement
    case .increment:
      self = .increment
    default:
      self = .none
    }
  }
}
