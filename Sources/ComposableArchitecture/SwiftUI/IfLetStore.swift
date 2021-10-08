#if canImport(SwiftUI)
import SwiftUI

public struct IfLetStore<State, Action, Content>: View where Content: View {
  private let content: (ViewStore<State?, Action>) -> Content
  private let store: Store<State?, Action>
  
  public init<IfContent, ElseContent>(
  _ store: Store<State?, Action>,
  @ViewBuilder then ifContent: @escaping (Store<State, Action>) -> IfContent,
  @ViewBuilder else elseContent: @escaping () -> ElseContent
    ) where Content == _ConditionalContent<IfContent, ElseContent> {
      self.store = store
      self.content = { viewStore in
        if var state = viewStore.state {
          return ViewBuilder.buildEither(
            first: ifContent(
              store.scope {
                state = $0 ?? state
                return state
              }
            )
          )
        } else {
          return ViewBuilder.buildEither(second: elseContent())
        }
      }
    }
  
  public init<IfContent>(
  _ store: Store<State?, Action>,
  @ViewBuilder then ifContent: @escaping (Store<State, Action>) -> IfContent
  ) where Content == IfContent? {
    self.store = store
    self.content = { viewStore in
      if var state = viewStore.state {
        return ifContent(
          store.scope {
            state = $0 ?? state
            return state
          }
        )
      } else {
        return nil
      }
    }
  }
  
  public var body: some View {
    WithViewStore(
      self.store,
      removeDuplicates: { ($0 != nil) == ($1 != nil) },
      content: self.content
    )
  }
}
#endif
