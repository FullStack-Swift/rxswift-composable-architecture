#if canImport(SwiftUI)
  import SwiftUI

  extension ViewStore {
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
    public func send(_ action: Action, animation: Animation?) {
      withAnimation(animation) {
        self.send(action)
      }
    }
  }
#endif
