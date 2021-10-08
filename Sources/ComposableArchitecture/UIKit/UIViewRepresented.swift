#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import UIKit

public struct UIViewRepresented<UIViewType>: UIViewRepresentable where UIViewType: UIView {
  public let makeUIView: (Context) -> UIViewType
  public let updateUIView: (UIViewType, Context) -> Void = { _, _ in }
  
  public init(makeUIView: @escaping (Context) -> UIViewType) {
    self.makeUIView = makeUIView
  }
  
  public func makeUIView(context: Context) -> UIViewType {
    self.makeUIView(context)
  }
  
  public func updateUIView(_ uiView: UIViewType, context: Context) {
    self.updateUIView(uiView, context)
  }
}
#endif
