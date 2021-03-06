import Combine
import SwiftUI

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Effect {
    /// Wraps an asynchronous unit of work in an effect.
    ///
    /// This function is useful for executing work in an asynchronous context and capture the
    /// result in an ``Effect`` so that the reducer, a non-asynchronous context, can process it.
    ///
    /// ```swift
    /// Effect.task {
    ///   guard case let .some((data, _)) = try? await URLSession.shared
    ///     .data(from: .init(string: "http://numbersapi.com/42")!)
    ///   else {
    ///     return "Could not load"
    ///   }
    ///
    ///   return String(decoding: data, as: UTF8.self)
    /// }
    /// ```
    ///
    /// Note that due to the lack of tools to control the execution of asynchronous work in Swift,
    /// it is not recommended to use this function in reducers directly. Doing so will introduce
    /// thread hops into your effects that will make testing difficult. You will be responsible
    /// for adding explicit expectations to wait for small amounts of time so that effects can
    /// deliver their output.
    ///
    /// Instead, this function is most helpful for calling `async`/`await` functions from the live
    /// implementation of dependencies, such as `URLSession.data`, `MKLocalSearch.start` and more.
    ///
    /// - Parameters:
    ///   - priority: Priority of the underlying task. If `nil`, the priority will come from
    ///     `Task.currentPriority`.
    ///   - operation: The operation to execute.
    /// - Returns: An effect wrapping the given asynchronous work.
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
        .do(afterError: {_ in
            task?.cancel()
        }, afterCompleted: {
            task?.cancel()
        }, onDispose: {
            task?.cancel()
        })
            .eraseToEffect()
            }
    /// Wraps an asynchronous unit of work in an effect.
    ///
    /// This function is useful for executing work in an asynchronous context and capture the
    /// result in an ``Effect`` so that the reducer, a non-asynchronous context, can process it.
    ///
    /// ```swift
    /// Effect.task {
    ///   let (data, _) = try await URLSession.shared
    ///     .data(from: .init(string: "http://numbersapi.com/42")!)
    ///
    ///   return String(decoding: data, as: UTF8.self)
    /// }
    /// ```
    ///
    /// Note that due to the lack of tools to control the execution of asynchronous work in Swift,
    /// it is not recommended to use this function in reducers directly. Doing so will introduce
    /// thread hops into your effects that will make testing difficult. You will be responsible
    /// for adding explicit expectations to wait for small amounts of time so that effects can
    /// deliver their output.
    ///
    /// Instead, this function is most helpful for calling `async`/`await` functions from the live
    /// implementation of dependencies, such as `URLSession.data`, `MKLocalSearch.start` and more.
    ///
    /// - Parameters:
    ///   - priority: Priority of the underlying task. If `nil`, the priority will come from
    ///     `Task.currentPriority`.
    ///   - operation: The operation to execute.
    /// - Returns: An effect wrapping the given asynchronous work.
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
#endif
