import ComposableArchitecture
import SwiftUI

struct MainView: View {
  
  private let store: Store<MainState, MainAction>
  
  @ObservedObject
  private var viewStore: ViewStore<ViewState, ViewAction>
  
  init(store: Store<MainState, MainAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: MainState(), reducer: MainReducer, environment: MainEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: MainAction.init))
  }
  
  var body: some View {
    ZStack {
      NavigationView {
        Form {
          Section {
            NavigationLink {
              CounterView()
            } label: {
              Text("Basics")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Pullback and combine")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Bindings")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Form bindings")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Optional state")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Shared state")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Alerts and Confirmation Dialogs")
            }
#if compiler(>=5.5)
            NavigationLink {
              CounterView()
            } label: {
              Text("Focus State")
            }
#endif
            NavigationLink {
              CounterView()
            } label: {
              Text("Animations")
            }
          } header: {
            Text("Getting started")
          }
          Section {
            NavigationLink {
              CounterView()
            } label: {
              Text("Basics")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Cancellation")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Long-living effects")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Refreshable")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Timers")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("System environment")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Web socket")
            }
          } header: {
            Text("Effects")
          }
          
          Section {
            NavigationLink {
              CounterView()
            } label: {
              Text("Navigate and load data")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Load data then navigate")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Lists: Navigate and load data")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Lists: Load data then navigate")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Sheets: Present and load data")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Sheets: Load data then present")
            }
            
          } header: {
            Text("Navigation")
          }
          
          
          Section {
            NavigationLink {
              CounterView()
            } label: {
              Text("Reusable favoriting component")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Reusable offline download component")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Lifecycle")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Strict reducers")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Elm-like subscriptions")
            }
            NavigationLink {
              CounterView()
            } label: {
              Text("Recursive state and actions")
            }
          } header: {
            Text("Higher-order reducers")
          }
        }
        .navigationBarTitle("Case Studies")
        .navigationViewStyle(.stack)
        .navigationBarItems(leading: leadingBarItems, trailing: trailingBarItems)
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

extension MainView {
  
  private var leadingBarItems: some View {
    CounterView()
  }
  
  private var trailingBarItems: some View {
    Button(action: {
      viewStore.send(.changeRootScreen(.auth))
    }, label: {
      Text("Logout")
        .foregroundColor(Color.blue)
    })
  }
}


struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    MainView()
  }
}

fileprivate struct ViewState: Equatable {
  
  init(state: MainState) {
    
  }
}

fileprivate enum ViewAction: Equatable {
  case viewOnAppear
  case viewOnDisappear
  case none
  case changeRootScreen(RootScreen)
  init(action: MainAction) {
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

fileprivate extension MainState {
  
  var viewState: ViewState {
    get {
      ViewState(state: self)
    }
    set {
      
    }
  }
  
}

fileprivate extension MainAction {
  
  init(action: ViewAction) {
    switch action {
    case .viewOnAppear:
      self = .viewOnAppear
    case .viewOnDisappear:
      self = .viewOnDisappear
    case .changeRootScreen(let screen):
      self = .changeRootScreen(screen)
    default:
      self = .none
    }
  }
}
