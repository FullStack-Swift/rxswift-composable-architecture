#if canImport(SwiftUI)
import OrderedCollections
import SwiftUI

public struct ForEachStore<EachState, EachAction, Data, ID, Content>: DynamicViewContent
where Data: Collection, ID: Hashable, Content: View {
  public let data: Data
  let content: () -> Content
  public init<EachContent>(
    _ store: Store<IdentifiedArray<ID, EachState>, (ID, EachAction)>,
    @ViewBuilder content: @escaping (Store<EachState, EachAction>) -> EachContent
  )
  where
EachContent: View,
  Data == IdentifiedArray<ID, EachState>,
  Content == WithViewStore<
    OrderedSet<ID>, (ID, EachAction), ForEach<OrderedSet<ID>, ID, EachContent>
  >
  {
    self.data = store.state.value
    self.content = {
      WithViewStore(store.scope(state: { $0.ids })) { viewStore in
        ForEach(viewStore.state, id: \.self) { id -> EachContent in
          var element = store.state.value[id: id]!
          return content(
            store.scope(
              state: {
                element = $0[id: id] ?? element
                return element
              },
              action: { (id, $0) }
            )
          )
        }
      }
    }
  }
  
  public var body: some View {
    self.content()
  }
}
#endif
