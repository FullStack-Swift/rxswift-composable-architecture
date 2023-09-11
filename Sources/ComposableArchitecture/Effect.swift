import Foundation
import SwiftUI
import XCTestDynamicOverlay

public struct Effect<Action> {
  @usableFromInline
  enum Operation {
    case none
    case publisher(Observable<Action>)
    case run(TaskPriority? = nil, @Sendable (Send<Action>) async -> Void)
  }

  @usableFromInline
  let operation: Operation

  @usableFromInline
  init(operation: Operation) {
    self.operation = operation
  }
}

/// A convenience type alias for referring to an effect of a given reducer's domain.
///
/// Instead of specifying the action:
///
/// ```swift
/// let effect: EffectTask<Feature.Action>
/// ```
///
/// You can specify the reducer:
///
/// ```swift
/// let effect: EffectOf<Feature>
/// ```
public typealias EffectOf<R: Reducer> = Effect<R.Action>


// MARK: - Creating Effects

extension Effect {
  /// An effect that does nothing and completes immediately. Useful for situations where you must
  /// return an effect, but you don't need to do anything.
  @inlinable
  public static var none: Self {
    Self(operation: .none)
  }

  /// Wraps an asynchronous unit of work that can emit any number of times in an effect.
  ///
  /// This effect is similar to ``task(priority:operation:catch:file:fileID:line:)`` except it is
  /// capable of emitting 0 or more times, not just once.
  ///
  /// For example, if you had an async stream in a dependency client:
  ///
  /// ```swift
  /// struct EventsClient {
  ///   var events: () -> AsyncStream<Event>
  /// }
  /// ```
  ///
  /// Then you could attach to it in a `run` effect by using `for await` and sending each action of
  /// the stream back into the system:
  ///
  /// ```swift
  /// case .startButtonTapped:
  ///   return .run { send in
  ///     for await event in self.events() {
  ///       send(.event(event))
  ///     }
  ///   }
  /// ```
  ///
  /// See ``Send`` for more information on how to use the `send` argument passed to `run`'s closure.
  ///
  /// The closure provided to ``run(priority:operation:catch:file:fileID:line:)`` is allowed to
  /// throw, but any non-cancellation errors thrown will cause a runtime warning when run in the
  /// simulator or on a device, and will cause a test failure in tests. To catch non-cancellation
  /// errors use the `catch` trailing closure.
  ///
  /// - Parameters:
  ///   - priority: Priority of the underlying task. If `nil`, the priority will come from
  ///     `Task.currentPriority`.
  ///   - operation: The operation to execute.
  ///   - catch: An error handler, invoked if the operation throws an error other than
  ///     `CancellationError`.
  /// - Returns: An effect wrapping the given asynchronous work.
  public static func run(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable (Send<Action>) async throws -> Void,
    catch handler: (@Sendable (Error, Send<Action>) async -> Void)? = nil,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    withEscapedDependencies { escaped in
      Self(
        operation: .run(priority) { send in
          await escaped.yield {
            do {
              try await operation(send)
            } catch is CancellationError {
              return
            } catch {
              guard let handler = handler else {
              #if DEBUG
                var errorDump = ""
                customDump(error, to: &errorDump, indent: 4)
                runtimeWarn(
                    """
                    An "EffectTask.run" returned from "\(fileID):\(line)" threw an unhandled error. …

                    \(errorDump)

                    All non-cancellation errors must be explicitly handled via the "catch" parameter \
                    on "EffectTask.run", or via a "do" block.
                    """
                )
              #endif
                return
              }
              await handler(error, send)
            }
          }
        }
      )
    }
  }

  /// Creates an effect that executes some work in the real world that doesn't need to feed data
  /// back into the store. If an error is thrown, the effect will complete and the error will be
  /// ignored.
  ///
  /// This effect is handy for executing some asynchronous work that your feature doesn't need to
  /// react to. One such example is analytics:
  ///
  /// ```swift
  /// case .buttonTapped:
  ///   return .fireAndForget {
  ///     try self.analytics.track("Button Tapped")
  ///   }
  /// ```
  ///
  /// The closure provided to ``fireAndForget(priority:_:)`` is allowed to throw, and any error
  /// thrown will be ignored.
  ///
  /// - Parameters:
  ///   - priority: Priority of the underlying task. If `nil`, the priority will come from
  ///     `Task.currentPriority`.
  ///   - work: A closure encapsulating some work to execute in the real world.
  /// - Returns: An effect.
  public static func fireAndForget(
    priority: TaskPriority? = nil,
    _ work: @escaping @Sendable () async throws -> Void
  ) -> Self {
    Self.run(priority: priority) { _ in try? await work() }
  }

  /// Initializes an effect that immediately emits the action passed in.
  ///
  /// > Note: We do not recommend using `Effect.send` to share logic. Instead, limit usage to
  /// > child-parent communication, where a child may want to emit a "delegate" action for a parent
  /// > to listen to.
  /// >
  /// > For more information, see <doc:Performance#Sharing-logic-with-actions>.
  ///
  /// - Parameter action: The action that is immediately emitted by the effect.
  public static func send(_ action: Action) -> Self {
    Self(operation: .publisher(.just(action)))
  }

  /// Initializes an effect that immediately emits the action passed in.
  ///
  /// > Note: We do not recommend using `Effect.send` to share logic. Instead, limit usage to
  /// > child-parent communication, where a child may want to emit a "delegate" action for a parent
  /// > to listen to.
  /// >
  /// > For more information, see <doc:Performance#Sharing-logic-with-actions>.
  ///
  /// - Parameters:
  ///   - action: The action that is immediately emitted by the effect.
  ///   - animation: An animation.
  public static func send(_ action: Action, animation: Animation? = nil) -> Self {
    .send(action).animation(animation)
  }
}

/// A type that can send actions back into the system when used from
/// ``Effect/run(priority:operation:catch:fileID:line:)``.
///
/// This type implements [`callAsFunction`][callAsFunction] so that you invoke it as a function
/// rather than calling methods on it:
///
/// ```swift
/// return .run { send in
///   send(.started)
///   defer { send(.finished) }
///   for await event in self.events {
///     send(.event(event))
///   }
/// }
/// ```
///
/// You can also send actions with animation:
///
/// ```swift
/// send(.started, animation: .spring())
/// defer { send(.finished, animation: .default) }
/// ```
///
/// See ``Effect/run(priority:operation:catch:fileID:line:)`` for more information on how to
/// use this value to construct effects that can emit any number of times in an asynchronous
/// context.
///
/// [callAsFunction]: https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID622
@MainActor
public struct Send<Action>: Sendable {
  let send: @MainActor @Sendable (Action) -> Void
  
  public init(send: @escaping @MainActor @Sendable (Action) -> Void) {
    self.send = send
  }
  
  /// Sends an action back into the system from an effect.
  ///
  /// - Parameter action: An action.
  public func callAsFunction(_ action: Action) {
    guard !Task.isCancelled else { return }
    self.send(action)
  }
  
  /// Sends an action back into the system from an effect with animation.
  ///
  /// - Parameters:
  ///   - action: An action.
  ///   - animation: An animation.
  public func callAsFunction(_ action: Action, animation: Animation?) {
    callAsFunction(action, transaction: Transaction(animation: animation))
  }
  
  /// Sends an action back into the system from an effect with transaction.
  ///
  /// - Parameters:
  ///   - action: An action.
  ///   - transaction: A transaction.
  public func callAsFunction(_ action: Action, transaction: Transaction) {
    guard !Task.isCancelled else { return }
    withTransaction(transaction) {
      self(action)
    }
  }
}

// MARK: - Composing Effects

extension Effect {
  /// Merges a variadic list of effects together into a single effect, which runs the effects at the
  /// same time.
  ///
  /// - Parameter effects: A list of effects.
  /// - Returns: A new effect
  @inlinable
  public static func merge(_ effects: Self...) -> Self {
    Self.merge(effects)
  }

  /// Merges a sequence of effects together into a single effect, which runs the effects at the same
  /// time.
  ///
  /// - Parameter effects: A sequence of effects.
  /// - Returns: A new effect
  @inlinable
  public static func merge<S: Sequence>(_ effects: S) -> Self where S.Element == Self {
    effects.reduce(.none) { $0.merge(with: $1) }
  }

  /// Merges this effect and another into a single effect that runs both at the same time.
  ///
  /// - Parameter other: Another effect.
  /// - Returns: An effect that runs this effect and the other at the same time.
  @inlinable
  public func merge(with other: Self) -> Self {
    switch (self.operation, other.operation) {
      case (_, .none):
        return self
      case (.none, _):
        return other
      case (.publisher, .publisher), (.run, .publisher), (.publisher, .run):
        return Self(
          operation: .publisher(
            Observable<Action>.merge(
              _EffectPublisher(self).asObservable(),
              _EffectPublisher(other).asObservable()
            )
          )
        )
      case let (.run(lhsPriority, lhsOperation), .run(rhsPriority, rhsOperation)):
        return Self(
          operation: .run { send in
            await withTaskGroup(of: Void.self) { group in
              group.addTask(priority: lhsPriority) {
                await lhsOperation(send)
              }
              group.addTask(priority: rhsPriority) {
                await rhsOperation(send)
              }
            }
          }
        )
    }
  }

  /// Concatenates a variadic list of effects together into a single effect, which runs the effects
  /// one after the other.
  ///
  /// - Parameter effects: A variadic list of effects.
  /// - Returns: A new effect
  @inlinable
  public static func concatenate(_ effects: Self...) -> Self {
    Self.concatenate(effects)
  }

  /// Concatenates a collection of effects together into a single effect, which runs the effects one
  /// after the other.
  ///
  /// - Parameter effects: A collection of effects.
  /// - Returns: A new effect
  @inlinable
  public static func concatenate<C: Collection>(_ effects: C) -> Self where C.Element == Self {
    effects.reduce(.none) { $0.concatenate(with: $1) }
  }

  /// Concatenates this effect and another into a single effect that first runs this effect, and
  /// after it completes or is cancelled, runs the other.
  ///
  /// - Parameter other: Another effect.
  /// - Returns: An effect that runs this effect, and after it completes or is cancelled, runs the
  ///   other.
  @inlinable
  @_disfavoredOverload
  public func concatenate(with other: Self) -> Self {
    switch (self.operation, other.operation) {
      case (_, .none):
        return self
      case (.none, _):
        return other
      case (.publisher, .publisher), (.run, .publisher), (.publisher, .run):
        return Self(
          operation: .publisher(
            Observable<Action>.concat(
              _EffectPublisher(self).asObservable(),
              _EffectPublisher(other).asObservable()
            )
          )
        )
      case let (.run(lhsPriority, lhsOperation), .run(rhsPriority, rhsOperation)):
        return Self(
          operation: .run { send in
            if let lhsPriority = lhsPriority {
              await Task(priority: lhsPriority) { await lhsOperation(send) }.cancellableValue
            } else {
              await lhsOperation(send)
            }
            if let rhsPriority = rhsPriority {
              await Task(priority: rhsPriority) { await rhsOperation(send) }.cancellableValue
            } else {
              await rhsOperation(send)
            }
          }
        )
    }
  }

  /// Transforms all elements from the upstream effect with a provided closure.
  ///
  /// - Parameter transform: A closure that transforms the upstream effect's action to a new action.
  /// - Returns: A publisher that uses the provided closure to map elements from the upstream effect
  ///   to new elements that it then publishes.
  @inlinable
  public func map<T>(_ transform: @escaping (Action) -> T) -> Effect<T> {
    switch self.operation {
      case .none:
        return .none
      case let .publisher(publisher):
        return .init(
          operation: .publisher(
            publisher
              .map(
                withEscapedDependencies { escaped in
                  { action in
                    escaped.yield {
                      transform(action)
                    }
                  }
                }
              )
              .asObservable()
          )
        )
      case let .run(priority, operation):
        return withEscapedDependencies { escaped in
            .init(
              operation: .run(priority) { send in
                await escaped.yield {
                  await operation(
                    Send<Action> { action in
                      send(transform(action))
                    }
                  )
                }
              }
            )
        }
    }
  }
}
