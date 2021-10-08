import CustomDump
import SwiftUI

#if compiler(>=5.4)
@dynamicMemberLookup
@propertyWrapper
public struct BindableState<Value> {
  
  public var wrappedValue: Value
  
  public init(wrappedValue: Value) {
    self.wrappedValue = wrappedValue
  }
  
  public var projectedValue: Self {
    get { self }
    set { self = newValue }
  }
  
  public subscript<Subject>(
    dynamicMember keyPath: WritableKeyPath<Value, Subject>
  ) -> BindableState<Subject> {
    get { .init(wrappedValue: self.wrappedValue[keyPath: keyPath]) }
    set { self.wrappedValue[keyPath: keyPath] = newValue.wrappedValue }
  }
}

extension BindableState: Equatable where Value: Equatable {}

extension BindableState: Hashable where Value: Hashable {}

extension BindableState: Decodable where Value: Decodable {
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      self.init(wrappedValue: try container.decode(Value.self))
    } catch {
      self.init(wrappedValue: try Value(from: decoder))
    }
  }
}

extension BindableState: Encodable where Value: Encodable {
  public func encode(to encoder: Encoder) throws {
    do {
      var container = encoder.singleValueContainer()
      try container.encode(self.wrappedValue)
    } catch {
      try self.wrappedValue.encode(to: encoder)
    }
  }
}

extension BindableState: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(reflecting: self.wrappedValue)
  }
}

extension BindableState: CustomDumpRepresentable {
  public var customDumpValue: Any {
    self.wrappedValue
  }
}

extension BindableState: CustomDebugStringConvertible where Value: CustomDebugStringConvertible {
  public var debugDescription: String {
    self.wrappedValue.debugDescription
  }
}

public protocol BindableAction {
  
  associatedtype State
  
  static func binding(_ action: BindingAction<State>) -> Self
}

extension BindableAction {
  
  public static func set<Value>(
    _ keyPath: WritableKeyPath<State, BindableState<Value>>,
    _ value: Value
  ) -> Self
  where Value: Equatable {
    self.binding(.set(keyPath, value))
  }
}

extension ViewStore {
  
  public func binding<Value>(
    _ keyPath: WritableKeyPath<State, BindableState<Value>>
  ) -> Binding<Value>
  where Action: BindableAction, Action.State == State, Value: Equatable {
    self.binding(
      get: { $0[keyPath: keyPath].wrappedValue },
      send: { .binding(.set(keyPath, $0)) }
    )
  }
}
#endif

public struct BindingAction<Root>: Equatable {
  public let keyPath: PartialKeyPath<Root>
  
  let set: (inout Root) -> Void
  let value: Any
  let valueIsEqualTo: (Any) -> Bool
  
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.keyPath == rhs.keyPath && lhs.valueIsEqualTo(rhs.value)
  }
}

#if compiler(>=5.4)
extension BindingAction {
  
  public static func set<Value>(
    _ keyPath: WritableKeyPath<Root, BindableState<Value>>,
    _ value: Value
  ) -> Self where Value: Equatable {
    .init(
      keyPath: keyPath,
      set: { $0[keyPath: keyPath].wrappedValue = value },
      value: value,
      valueIsEqualTo: { $0 as? Value == value }
    )
  }
  
  public static func ~= <Value>(
    keyPath: WritableKeyPath<Root, BindableState<Value>>,
    bindingAction: Self
  ) -> Bool {
    keyPath == bindingAction.keyPath
  }
}
#endif

extension BindingAction {
  
  public func pullback<NewRoot>(
    _ keyPath: WritableKeyPath<NewRoot, Root>
  ) -> BindingAction<NewRoot> {
    .init(
      keyPath: (keyPath as AnyKeyPath).appending(path: self.keyPath) as! PartialKeyPath<NewRoot>,
      set: { self.set(&$0[keyPath: keyPath]) },
      value: self.value,
      valueIsEqualTo: self.valueIsEqualTo
    )
  }
}

extension BindingAction: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    .init(
      self,
      children: [
        "set": (self.keyPath, self.value)
      ],
      displayStyle: .enum
    )
  }
}

#if compiler(>=5.4)
extension Reducer where Action: BindableAction, State == Action.State {
  public func binding() -> Self {
    Self { state, action, environment in
      guard let bindingAction = (/Action.binding).extract(from: action)
      else {
        return self.run(&state, action, environment)
      }
      
      bindingAction.set(&state)
      return self.run(&state, action, environment)
    }
  }
}
#endif
