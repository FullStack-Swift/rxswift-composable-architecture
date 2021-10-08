@dynamicMemberLookup
public struct Identified<ID, Value>: Identifiable where ID: Hashable {
  public let id: ID
  public var value: Value

  public init(_ value: Value, id: ID) {
    self.id = id
    self.value = value
  }

  public init(_ value: Value, id: (Value) -> ID) {
    self.init(value, id: id(value))
  }

  public init(_ value: Value, id: KeyPath<Value, ID>) {
    self.init(value, id: value[keyPath: id])
  }

  public subscript<LocalValue>(
    dynamicMember keyPath: WritableKeyPath<Value, LocalValue>
  ) -> LocalValue {
    get { self.value[keyPath: keyPath] }
    set { self.value[keyPath: keyPath] = newValue }
  }
}

extension Identified: Decodable where ID: Decodable, Value: Decodable {}

extension Identified: Encodable where ID: Encodable, Value: Encodable {}

extension Identified: Equatable where Value: Equatable {}

extension Identified: Hashable where Value: Hashable {}
