#if canImport(SwiftUI)

import CustomDump
import SwiftUI

@available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
public struct ActionSheetState<Action> {
  public let id = UUID()
  public var buttons: [Button]
  public var message: TextState?
  public var title: TextState
  
  public init(
    title: TextState,
    message: TextState? = nil,
    buttons: [Button]
  ) {
    self.buttons = buttons
    self.message = message
    self.title = title
  }
  
  public typealias Button = AlertState<Action>.Button
}

@available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
extension ActionSheetState: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    Mirror(
      self,
      children: [
        "title": self.title,
        "message": self.message as Any,
        "buttons": self.buttons,
      ],
      displayStyle: .struct
    )
  }
}

@available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
extension ActionSheetState: Equatable where Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.title == rhs.title
    && lhs.message == rhs.message
    && lhs.buttons == rhs.buttons
  }
}

@available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
extension ActionSheetState: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.title)
    hasher.combine(self.message)
    hasher.combine(self.buttons)
  }
}

@available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
extension ActionSheetState: Identifiable {}

@available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
@available(macOS, unavailable)
extension View {
  public func actionSheet<Action>(_ store: Store<ActionSheetState<Action>?, Action>,dismiss: Action) -> some View {
    WithViewStore(store, removeDuplicates: { $0?.id == $1?.id }) { viewStore in
      self.actionSheet(item: viewStore.binding(send: dismiss)) { state in
        state.toSwiftUI(send: viewStore.send)
      }
    }
  }
}

@available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
@available(macOS, unavailable)
extension ActionSheetState {
  fileprivate func toSwiftUI(send: @escaping (Action) -> Void) -> SwiftUI.ActionSheet {
    SwiftUI.ActionSheet(
      title: Text(self.title),
      message: self.message.map { Text($0) },
      buttons: self.buttons.map {
        $0.toSwiftUI(send: send)
      }
    )
  }
}
#endif
