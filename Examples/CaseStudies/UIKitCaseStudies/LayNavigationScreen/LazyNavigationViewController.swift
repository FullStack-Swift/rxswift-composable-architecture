import ComposableArchitecture
import SwiftUI
import UIKit

final class LazyNavigationViewController: UIViewController {
  
  private let store: Store<LazyNavigationState, LazyNavigationAction>
  
  private let viewStore: ViewStore<ViewState, ViewAction>
  
  private let disposeBag = DisposeBag()
  
  init(store: Store<LazyNavigationState, LazyNavigationAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: LazyNavigationState(), reducer: LazyNavigationReducer, environment: LazyNavigationEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: LazyNavigationAction.init))
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewStore.send(.viewDidLoad)
    title = "Lazy Navigation"
    view.backgroundColor = .white
    let button = UIButton(type: .system)
    button.setTitle("Load optional counter", for: .normal)
    let activityIndicator = UIActivityIndicatorView()
    activityIndicator.startAnimating()
    let rootStackView = UIStackView(arrangedSubviews: [
      button,
      activityIndicator,
    ])
    rootStackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(rootStackView)
    NSLayoutConstraint.activate([
      rootStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      rootStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
    
    button.rx.tap
      .map{ViewAction.setNavigation(isActive: true)}
      .bind(to: viewStore.action)
      .disposed(by: disposeBag)
    viewStore.publisher.isActivityIndicatorHidden
      .bind(to: activityIndicator.rx.isHidden)
      .disposed(by: disposeBag)
    
    store.scope(state: { $0.optionalCounter }, action: LazyNavigationAction.optionalCounter)
      .ifLet(
        then: { [weak self] store in
          guard let self = self else { return }
          self.navigationController?.pushViewController(CounterViewController(store: store), animated: true)
        },
        else: { [weak self] in
          guard let self = self else { return }
          self.navigationController?.popToViewController(self, animated: true)
        }
      ).disposed(by: disposeBag)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewStore.send(.viewWillAppear)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !self.isMovingToParent {
      self.viewStore.send(.setNavigation(isActive: false))
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewStore.send(.viewWillDisappear)
  }
  
}

struct LazyNavigationViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = LazyNavigationViewController()
    UIViewRepresented(makeUIView: { _ in vc.view })
  }
}

fileprivate struct ViewState: Equatable {
  var optionalCounter: CounterState?
  var isActivityIndicatorHidden = true
  init(state: LazyNavigationState) {
    self.optionalCounter = state.optionalCounter
    self.isActivityIndicatorHidden = state.isActivityIndicatorHidden
  }
}

fileprivate enum ViewAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case optionalCounter(CounterAction)
  case setNavigation(isActive: Bool)
  case setNavigationIsActiveDelayCompleted
  
  init(action: LazyNavigationAction) {
    switch action {
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    default:
      self = .none
    }
  }
}

fileprivate extension LazyNavigationState {
  var viewState: ViewState {
    get {
      ViewState(state: self)
    }
    set {
      
    }
  }
}

fileprivate extension LazyNavigationAction {
  
  init(action: ViewAction) {
    switch action {
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    case .optionalCounter(let counterAction):
      self = .optionalCounter(counterAction)
    case .setNavigation(let isActive):
      self = .setNavigation(isActive: isActive)
    case .setNavigationIsActiveDelayCompleted:
      self = .setNavigationIsActiveDelayCompleted
    default:
      self = .none
    }
  }
}
