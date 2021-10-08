import SwiftUI

@main
struct TodosApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
#if os(macOS)
        .frame(minWidth: 700, idealWidth: 700, maxWidth: .infinity, minHeight: 500, idealHeight: 500, maxHeight: .infinity, alignment: .center)
#endif
    }
  }
}
