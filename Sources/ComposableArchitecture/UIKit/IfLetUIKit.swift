import RxSwift

extension Store {
  @discardableResult
  public func ifLet<Wrapped>(
    then unwrap: @escaping (Store<Wrapped, Action>) -> Void,
    else: @escaping () -> Void = {}
  ) -> Disposable where State == Wrapped? {
    let disposable = self.state
      .distinctUntilChanged({ ($0 != nil) == ($1 != nil) })
      .observe(on: MainScheduler.instance)
      .subscribe (onNext: { state in
        if var state = state {
          unwrap(
            self.scope {
              state = $0 ?? state
              return state
            })
        } else {
          `else`()
        }
      })
    return disposable
  }
}
