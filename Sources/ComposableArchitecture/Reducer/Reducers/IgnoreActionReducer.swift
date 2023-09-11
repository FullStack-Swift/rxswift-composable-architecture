
public struct IgnoreActionReducer<State, Action>: Reducer {
  @usableFromInline
  let ignoreStateReducer: (inout State) -> Void

  @usableFromInline
  init(
    internal ignoreStateReducer: @escaping (inout State) -> Void
  ) {
    self.ignoreStateReducer = ignoreStateReducer
  }

  /// Initializes a reducer with a `reduce` function.
  ///
  /// - Parameter reduce: A function that is called when ``reduce(into:action:)`` is invoked.
  @inlinable
  public init(_ ignoreStateReducer: @escaping (inout State) -> Void) {
    self.init(internal: ignoreStateReducer)
  }

  @inlinable
  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    self.ignoreStateReducer(&state)
    return .none
  }
}
