import RxRelay

extension BehaviorRelay {
  public func commit(_ block: (inout Element) -> Void) {
    var clone = self.value
    block(&clone)
    self.accept(clone)
  }
}
