import RxRelay
import RxSwift

#if canImport(Combine)
import Combine
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

@dynamicMemberLookup
public final class ViewStore<State, Action> {
#if canImport(Combine)
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public private(set) lazy var objectWillChange = ObservableObjectPublisher()
#endif
  private let _send: (Action) -> Void
  fileprivate var _state: BehaviorRelay<State>
  private var viewDisposable: Disposable?
  deinit {
    viewDisposable?.dispose()
  }
  
  public init(_ store: Store<State, Action>, removeDuplicates isDuplicate: @escaping (State, State) -> Bool) {
    self._send = { store.send($0) }
    self._state = BehaviorRelay(value: store.state.value)
    self.viewDisposable = store.state
      .distinctUntilChanged(isDuplicate).subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        self._state.accept($0)
#if canImport(Combine)
        if #available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *) {
          self.objectWillChange.send()
          self._state.accept($0)
        }
#endif
      })
  }
  
  public var publisher: StorePublisher<State> {
    StorePublisher(viewStore: self)
  }
  
  public var state: State {
    self._state.value
  }
  
  public var action: Binder<Action> {
    Binder(self) { weakSelf, action in
      weakSelf.send(action)
    }
  }
  
  public func send(_ action: Action) {
    self._send(action)
  }
  
  public subscript<LocalState>(dynamicMember keyPath: KeyPath<State, LocalState>) -> LocalState {
    self._state.value[keyPath: keyPath]
  }
  
#if canImport(SwiftUI)
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func binding<LocalState>(
    get: @escaping (State) -> LocalState,
    send localStateToViewAction: @escaping (LocalState) -> Action
  ) -> Binding<LocalState> {
    ObservedObject(wrappedValue: self)
      .projectedValue[get: .init(rawValue: get), send: .init(rawValue: localStateToViewAction)]
  }
  
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func binding<LocalState>(
    get: @escaping (State) -> LocalState,
    send action: Action
  ) -> Binding<LocalState> {
    self.binding(get: get, send: { _ in action })
  }
  
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func binding(
    send localStateToViewAction: @escaping (State) -> Action
  ) -> Binding<State> {
    self.binding(get: { $0 }, send: localStateToViewAction)
  }
  
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func binding(send action: Action) -> Binding<State> {
    self.binding(send: { _ in action })
  }
#endif
  
  private subscript<LocalState>(
    get state: HashableWrapper<(State) -> LocalState>,
    send action: HashableWrapper<(LocalState) -> Action>
  ) -> LocalState {
    get { state.rawValue(self.state) }
    set { self.send(action.rawValue(newValue)) }
  }
  
}

extension ViewStore where State: Equatable {
  public convenience init(_ store: Store<State, Action>) {
    self.init(store, removeDuplicates: ==)
  }
}

extension ViewStore where State == Void {
  public convenience init(_ store: Store<Void, Action>) {
    self.init(store, removeDuplicates: ==)
  }
}

#if canImport(Combine)
extension ViewStore: ObservableObject {
  
}
#endif

@dynamicMemberLookup
public struct StorePublisher<State>: ObservableType {
  public typealias Element = State
  public let upstream: Observable<State>
  public let viewStore: Any
  private let disposeBag = DisposeBag()
  
  fileprivate init<Action>(viewStore: ViewStore<State, Action>) {
    self.viewStore = viewStore
    self.upstream = viewStore._state.asObservable()
  }
  
  public func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer: ObserverType, Element == Observer.Element {
    upstream.asObservable().subscribe { event in
      switch event {
      case .error, .completed:
        _ = viewStore
      default:
        break
      }
    }
    .disposed(by: disposeBag)
    return upstream.subscribe(observer)
  }
  
  private init(_ upstream: Observable<State>, viewStore: Any) {
    self.upstream = upstream
    self.viewStore = viewStore
  }
  
  public subscript<LocalState>(dynamicMember keyPath: KeyPath<State, LocalState>) -> StorePublisher<LocalState> where LocalState: Equatable {
    .init(self.upstream.map { $0[keyPath: keyPath] }.distinctUntilChanged(), viewStore: viewStore)
  }
}

private struct HashableWrapper<Value>: Hashable {
  let rawValue: Value
  static func == (lhs: Self, rhs: Self) -> Bool { false }
  func hash(into hasher: inout Hasher) {}
}
