import Combine
import SwiftUI

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Effect {
  public static func task(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Value
  ) -> Self {
    var task: Task<Void, Never>?
    return Effect.future { callback in
      task = Task(priority: priority) {
        guard !Task.isCancelled else { return }
        let output = await operation()
        guard !Task.isCancelled else { return }
        callback(.success(output))
      }
    }
    .asPublisher()
    .handleEvents(receiveCancel: { task?.cancel() })
    .eraseToEffect()
  }
  public static func task(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Value
  ) -> Self {
    Deferred<Publishers.HandleEvents<PassthroughSubject<Value, Error>>> {
      let subject = PassthroughSubject<Value, Error>()
      let task = Task(priority: priority) {
        do {
          try Task.checkCancellation()
          let output = try await operation()
          try Task.checkCancellation()
          subject.send(output)
          subject.send(completion: .finished)
        } catch is CancellationError {
          subject.send(completion: .finished)
        } catch {
          subject.send(completion: .failure(error))
        }
      }
      return subject.handleEvents(receiveCancel: task.cancel)
    }
    .eraseToEffect()
  }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension ViewStore {
  public func send(
    _ action: Action,
    while predicate: @escaping (State) -> Bool
  ) async {
    self.send(action)
    await self.suspend(while: predicate)
  }
  
  public func send(
    _ action: Action,
    animation: Animation?,
    while predicate: @escaping (State) -> Bool
  ) async {
    withAnimation(animation) { self.send(action) }
    await self.suspend(while: predicate)
  }
  
  public func suspend(while predicate: @escaping (State) -> Bool) async {
    _ = await self.publisher.eraseToEffect().asPublisher().assertNoFailure()
      .values
      .first(where: { !predicate($0) })
  }
}
#endif
