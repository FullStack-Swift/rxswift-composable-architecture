import ComposableArchitecture
import SwiftUI
import UIKit

struct CaseStudy {
  let title: String
  let viewController: () -> UIViewController
  
  init(title: String, viewController: @autoclosure @escaping () -> UIViewController) {
    self.title = title
    self.viewController = viewController
  }
}

let dataSource: [CaseStudy] = [
  CaseStudy(title: "Basics",viewController: CounterViewController()),
  CaseStudy(title: "Lists",viewController: CountersTableViewController()),
  CaseStudy(title: "Eager Navigation",viewController: EagerNavigationViewController()),
  CaseStudy(title: "Lazy Navigation",viewController: LazyNavigationViewController()),
]


final class MainViewController: UIViewController {
  
  private var store: Store<MainState, MainAction>!
  
  private var viewStore: ViewStore<ViewState, ViewAction>!
  
  private var disposeBag = DisposeBag()
  
  @IBOutlet private weak var tableView: UITableView!
  
  init(store: Store<MainState, MainAction>? = nil) {
    super.init(nibName: nil, bundle: nil)
    setStore(store: store)
  }
  
  static func fromStoryboard(store: Store<MainState, MainAction>? = nil) -> MainViewController {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
    vc.setStore(store: store)
    return vc
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  private func setStore(store: Store<MainState, MainAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: MainState(), reducer: MainReducer, environment: MainEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: MainAction.init))
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewStore.send(.viewDidLoad)
    title = "Case Studies"
    navigationController?.navigationBar.prefersLargeTitles = true
    tableView.delegate = self
    tableView.dataSource = self
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewStore.send(.viewWillAppear)
    tableView.reloadData()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewStore.send(.viewWillDisappear)
  }
  
  @objc private func logout() {
    viewStore.send(.logout)
  }
}

extension MainViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)-> UITableViewCell {
    let caseStudy = dataSource[indexPath.row]
    let cell = UITableViewCell()
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.text = caseStudy.title
    return cell
  }
}

extension MainViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let caseStudy = dataSource[indexPath.row]
    self.navigationController?.pushViewController(caseStudy.viewController(), animated: true)
  }
}

struct MainViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = MainViewController()
    UIViewRepresented(makeUIView: { _ in vc.view })
  }
}

fileprivate struct ViewState: Equatable {
  
  init(state: MainState) {
    
  }
}

fileprivate enum ViewAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case logout
  init(action: MainAction) {
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
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    case .logout:
      self = .logout
    default:
      self = .none
    }
  }
}
