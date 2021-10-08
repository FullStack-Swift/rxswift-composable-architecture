import ComposableArchitecture
import SwiftUI
import UIKit

final class CountersTableViewController: UITableViewController {
  
  private let store: Store<CountersTableState, CountersTableAction>
  
  private let viewStore: ViewStore<ViewState, ViewAction>
  
  private let disposeBag = DisposeBag()
  
  private let cellIdentifier = "Cell"
  
  private var dataSource: [CounterState] = []
  
  init(store: Store<CountersTableState, CountersTableAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: CountersTableState(), reducer: CountersTableReducer, environment: CountersTableEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: CountersTableAction.init))
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewStore.send(.viewDidLoad)
    self.title = "Lists"
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    self.viewStore.publisher.counters
      .subscribe(onNext: { [weak self] in
        guard let self = self else {return}
        self.dataSource = $0
        self.tableView.reloadData()
      })
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
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    self.dataSource.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.text = "\(self.dataSource[indexPath.row].count)"
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    navigationController?.pushViewController(
      CounterViewController(
        store: store.scope(
          state: { $0.counters[indexPath.row] },
          action: { .counter(index: indexPath.row, action: $0) }
        )
      ),
      animated: true
    )
  }
}

struct CountersTableViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = CountersTableViewController()
    UIViewRepresented(makeUIView: { _ in vc.view })
  }
}

fileprivate struct ViewState: Equatable {
  var counters: [CounterState] = []
  init(state: CountersTableState) {
    self.counters = state.counters
  }
}

fileprivate enum ViewAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  
  init(action: CountersTableAction) {
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

fileprivate extension CountersTableState {
  
  var viewState: ViewState {
    get {
      ViewState(state: self)
    }
    set {
      
    }
  }
}

fileprivate extension CountersTableAction {
  
  init(action: ViewAction) {
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
