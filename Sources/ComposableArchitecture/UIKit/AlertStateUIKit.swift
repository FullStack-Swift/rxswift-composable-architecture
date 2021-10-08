#if canImport(UIKit) && !os(watchOS)
import UIKit

@available(iOS 13, *)
@available(macCatalyst 13, *)
@available(macOS, unavailable)
@available(tvOS 13, *)
@available(watchOS, unavailable)
extension UIAlertController {
  public convenience init<Action>(
    state: AlertState<Action>,
    send: @escaping (Action) -> Void
  ) {
    self.init(
      title: String(state: state.title),
      message: state.message.map { String(state: $0) },
      preferredStyle: .alert)
    
    if let primaryButton = state.primaryButton {
      self.addAction(primaryButton.toUIAlertAction(send: send))
    }
    
    if let secondaryButton = state.secondaryButton {
      self.addAction(secondaryButton.toUIAlertAction(send: send))
    }
  }
  
  public convenience init<Action>(
    state: ActionSheetState<Action>, send: @escaping (Action) -> Void
  ) {
    self.init(
      title: String(state: state.title),
      message: state.message.map { String(state: $0) },
      preferredStyle: .actionSheet)
    
    state.buttons.forEach { button in
      self.addAction(button.toUIAlertAction(send: send))
    }
  }
}

@available(iOS 13, *)
@available(macCatalyst 13, *)
@available(macOS, unavailable)
@available(tvOS 13, *)
@available(watchOS, unavailable)
extension AlertState.Button {
  func toUIAlertAction(send: @escaping (Action) -> Void) -> UIAlertAction {
    let action = {
      switch self.action?.type {
      case .none:
        return
      case let .some(.send(action)),
        let .some(.animatedSend(action, animation: _)):  // Doesn't support animation in UIKit
        send(action)
      }
    }
    switch self.type {
    case let .cancel(.some(title)):
      return UIAlertAction(
        title: String(state: title), style: .cancel, handler: { _ in action() })
    case .cancel(.none):
      return UIAlertAction(title: nil, style: .cancel, handler: { _ in action() })
    case let .default(title):
      return UIAlertAction(
        title: String(state: title), style: .default, handler: { _ in action() })
    case let .destructive(title):
      return UIAlertAction(
        title: String(state: title), style: .destructive, handler: { _ in action() })
    }
  }
}
#endif
