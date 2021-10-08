import ComposableArchitecture
import SwiftUI
import UIKit
import RxCocoa
import RxSwift

final class AuthViewController: UIViewController {
  
  private var store: Store<AuthState, AuthAction>!
  
  private var viewStore: ViewStore<ViewState, ViewAction>!
  
  private let disposeBag = DisposeBag()
  
  @IBOutlet weak private var btnLogin: UIButton!
  
  init(store: Store<AuthState, AuthAction>? = nil) {
    super.init(nibName: nil, bundle: nil)
    setStore(store: store)
  }
  
  static func fromStoryboard(store: Store<AuthState, AuthAction>? = nil) -> AuthViewController {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as! AuthViewController
    vc.setStore(store: store)
    return vc
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  private func setStore(store: Store<AuthState, AuthAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: AuthState(), reducer: AuthReducer, environment: AuthEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: AuthAction.init))
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewStore.send(.viewDidLoad)
    btnLogin.rx.tap
      .map{ViewAction.clickBtnLogin}
      .bind(to: viewStore.action)
      .disposed(by: disposeBag)
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

struct AuthViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = AuthViewController()
    UIViewRepresented(makeUIView: { _ in vc.view })
  }
}

fileprivate struct ViewState: Equatable {
  
  init(state: AuthState) {
    
  }
}

fileprivate enum ViewAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case clickBtnLogin
  
  init(action: AuthAction) {
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

fileprivate extension AuthState {
  
  var viewState: ViewState {
    get {
      ViewState(state: self)
    }
    set {
      
    }
  }
}

fileprivate extension AuthAction {
  
  init(action: ViewAction) {
    switch action {
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    case .clickBtnLogin:
      self = .login
    default:
      self = .none
    }
  }
}
