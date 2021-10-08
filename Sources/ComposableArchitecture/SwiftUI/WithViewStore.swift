#if canImport(SwiftUI)
import Combine
import CustomDump
import SwiftUI

public struct WithViewStore<State, Action, Content> {
  private let content: (ViewStore<State, Action>) -> Content
#if DEBUG
  private let file: StaticString
  private let line: UInt
  private var prefix: String?
  private var previousState: (State) -> State?
#endif
  @ObservedObject private var viewStore: ViewStore<State, Action>
  
  fileprivate init(
    store: Store<State, Action>,
    removeDuplicates isDuplicate: @escaping (State, State) -> Bool,
    file: StaticString = #fileID,
    line: UInt = #line,
    content: @escaping (ViewStore<State, Action>) -> Content
  ) {
    self.content = content
#if DEBUG
    self.file = file
    self.line = line
    var previousState: State? = nil
    self.previousState = { currentState in
      defer { previousState = currentState }
      return previousState
    }
#endif
    self.viewStore = ViewStore(store, removeDuplicates: isDuplicate)
  }
  
  public func debug(_ prefix: String = "") -> Self {
    var view = self
#if DEBUG
    view.prefix = prefix
#endif
    return view
  }
  
  fileprivate var _body: Content {
#if DEBUG
    if let prefix = self.prefix {
      let difference =
      self.previousState(self.viewStore.state)
        .map {
          diff($0, self.viewStore.state).map { "(Changed state)\n\($0)" }
          ?? "(No difference in state detected)"
        }
      ?? "(Initial state)\n\(customDump(self.viewStore.state, indent: 2))"
      func typeName(_ type: Any.Type) -> String {
        var name = String(reflecting: type)
        if let index = name.firstIndex(of: ".") {
          name.removeSubrange(...index)
        }
        return name
      }
      print(
          """
          \(prefix.isEmpty ? "" : "\(prefix): ")\
          WithViewStore<\(typeName(State.self)), \(typeName(Action.self)), _>\
          @\(self.file):\(self.line) \(difference)
          """
      )
    }
#endif
    return self.content(self.viewStore)
  }
}

extension WithViewStore: View where Content: View {
  
  public init(
    _ store: Store<State, Action>,
    removeDuplicates isDuplicate: @escaping (State, State) -> Bool,
    file: StaticString = #fileID,
    line: UInt = #line,
    @ViewBuilder content: @escaping (ViewStore<State, Action>) -> Content
  ) {
    self.init(
      store: store,
      removeDuplicates: isDuplicate,
      file: file,
      line: line,
      content: content
    )
  }
  
  public var body: Content {
    self._body
  }
}

extension WithViewStore where State: Equatable, Content: View {
  
  public init(
    _ store: Store<State, Action>,
    file: StaticString = #fileID,
    line: UInt = #line,
    @ViewBuilder content: @escaping (ViewStore<State, Action>) -> Content
  ) {
    self.init(store, removeDuplicates: ==, file: file, line: line, content: content)
  }
}

extension WithViewStore where State == Void, Content: View {
  
  public init(
    _ store: Store<State, Action>,
    file: StaticString = #fileID,
    line: UInt = #line,
    @ViewBuilder content: @escaping (ViewStore<State, Action>) -> Content
  ) {
    self.init(store, removeDuplicates: ==, file: file, line: line, content: content)
  }
}

extension WithViewStore: DynamicViewContent where State: Collection, Content: DynamicViewContent {
  public typealias Data = State
  
  public var data: State {
    self.viewStore.state
  }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
extension WithViewStore: Scene where Content: Scene {
  
  public init(
    _ store: Store<State, Action>,
    removeDuplicates isDuplicate: @escaping (State, State) -> Bool,
    file: StaticString = #fileID,
    line: UInt = #line,
    @SceneBuilder content: @escaping (ViewStore<State, Action>) -> Content
  ) {
    self.init(
      store: store,
      removeDuplicates: isDuplicate,
      file: file,
      line: line,
      content: content
    )
  }
  
  public var body: Content {
    self._body
  }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
extension WithViewStore where State: Equatable, Content: Scene {
  
  public init(
    _ store: Store<State, Action>,
    file: StaticString = #fileID,
    line: UInt = #line,
    @SceneBuilder content: @escaping (ViewStore<State, Action>) -> Content
  ) {
    self.init(store, removeDuplicates: ==, file: file, line: line, content: content)
  }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
extension WithViewStore where State == Void, Content: Scene {
  
  public init(
    _ store: Store<State, Action>,
    file: StaticString = #fileID,
    line: UInt = #line,
    @SceneBuilder content: @escaping (ViewStore<State, Action>) -> Content
  ) {
    self.init(store, removeDuplicates: ==, file: file, line: line, content: content)
  }
}
#endif
