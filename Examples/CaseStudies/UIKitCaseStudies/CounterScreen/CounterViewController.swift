import ComposableArchitecture
import SwiftUI
import UIKit

final class CounterViewController: UIViewController {
  
  private let store: Store<CounterState, CounterAction>
  
  private let viewStore: ViewStore<ViewState, ViewAction>
  
  private let disposeBag = DisposeBag()
  
  init(store: Store<CounterState, CounterAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: CounterState(), reducer: CounterReducer, environment: CounterEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: CounterAction.init))
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewStore.send(.viewDidLoad)
    view.backgroundColor = .white
    let decrementButton = UIButton(type: .system)
    decrementButton.setTitle("−", for: .normal)
    let countLabel = UILabel()
    countLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
    let incrementButton = UIButton(type: .system)
    incrementButton.setTitle("+", for: .normal)
    let rootStackView = UIStackView(arrangedSubviews: [
      decrementButton,
      countLabel,
      incrementButton,
    ])
    rootStackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(rootStackView)
    NSLayoutConstraint.activate([
      rootStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      rootStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
    decrementButton.rx.tap
      .map{ViewAction.decrementButtonTapped}
      .bind(to: viewStore.action)
      .disposed(by: disposeBag)
    incrementButton.rx.tap
      .map{ViewAction.incrementButtonTapped}
      .bind(to: viewStore.action)
      .disposed(by: disposeBag)
    viewStore.publisher.count
      .map { "\($0)" }
      .bind(to: countLabel.rx.text)
      .disposed(by: disposeBag)
    //        viewStore.publisher.count
    //            .map{"\($0)"}
    //            .assign(to: \.text, on: countLabel)
    //            .disposed(by: disposeBag)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewStore.send(.viewWillAppear)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewStore.send(.viewWillDisappear)
  }
}

struct CounterViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = CounterViewController()
    UIViewRepresented(makeUIView: { _ in vc.view })
  }
}

fileprivate struct ViewState: Equatable {
  var count = 0
  init(state: CounterState) {
    self.count = state.count
  }
}

fileprivate enum ViewAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case decrementButtonTapped
  case incrementButtonTapped
  
  init(action: CounterAction) {
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
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    case .incrementButtonTapped:
      self = .incrementButtonTapped
    case .decrementButtonTapped:
      self = .decrementButtonTapped
    default:
      self = .none
    }
  }
}
