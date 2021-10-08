import XCTestDynamicOverlay

extension Effect {
  public static func failing(_ prefix: String) -> Self {
    .fireAndForget {
      XCTFail("\(prefix.isEmpty ? "" : "\(prefix) - ")A failing effect ran.")
    }
  }
}
