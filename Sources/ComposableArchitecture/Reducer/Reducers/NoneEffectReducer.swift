/// A type-erased reducer that invokes the given `reduce` function.
///
/// ``NoneEffectReducer`` is useful for injecting logic into a reducer tree without the effecttask
public struct NoneEffectReducer<State, Action>: Reducer {

  @usableFromInline
  let noneEffectReducer: (inout State, Action) -> Void

  @usableFromInline
  init(
    internal noneEffectReducer: @escaping (inout State, Action) -> Void
  ) {
    self.noneEffectReducer = noneEffectReducer
  }

  /// Initializes a reducer with a `reduce` function.
  ///
  /// - Parameter reduce: A function that is called when ``reduce(into:action:)`` is invoked.
  @inlinable
  public init(_ noneEffectReducer: @escaping (inout State, Action) -> Void) {
    self.init(internal: noneEffectReducer)
  }

  /// Type-erases a reducer.
  ///
  /// - Parameter reducer: A reducer that is called when ``reduce(into:action:)`` is invoked.
  @inlinable
  public init<R: Reducer>(_ reducer: R)
  where R.State == State, R.Action == Action {
    self.init(internal: {_ = reducer.reduce(into: &$0, action: $1)})
  }

  @inlinable
  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    self.noneEffectReducer(&state, action)
    return .none
  }
}
