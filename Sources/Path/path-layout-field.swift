import Foundation

/// Typed identity for a value derived from a path layout.
public struct PathField<Value: Sendable>: Sendable, Hashable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}

/// Values supplied to a layout renderer or returned by a decoder.
public struct PathLayoutValues: Sendable {
    internal var storage: [String: any Sendable] = [:]

    public init() {}

    public mutating func set<Value: Sendable>(
        _ value: Value,
        for field: PathField<Value>
    ) {
        storage[field.name] = value
    }

    public func value<Value: Sendable>(
        for field: PathField<Value>
    ) -> Value? {
        storage[field.name] as? Value
    }

    public func require<Value: Sendable>(
        _ field: PathField<Value>
    ) throws -> Value {
        guard let value = value(for: field) else {
            throw PathLayoutError.missingField(field.name)
        }
        return value
    }
}

/// Original input positions are relative to the complete decoded path.
public struct PathLayoutCapture: Sendable, Equatable {
    public let segments: [String]
    public let range: Range<Int>

    public init(segments: [String], range: Range<Int>) {
        self.segments = segments
        self.range = range
    }
}

public struct PathLayoutMatch: Sendable {
    public let values: PathLayoutValues
    public let captures: [String: PathLayoutCapture]
    public let matchedRange: Range<Int>

    public func value<Value: Sendable>(
        for field: PathField<Value>
    ) throws -> Value {
        try values.require(field)
    }

    public func source<Value: Sendable>(
        for field: PathField<Value>
    ) -> PathLayoutCapture? {
        captures[field.name]
    }
}

public enum PathLayoutError: Error, Sendable, Equatable {
    case invalidLayout(String)
    case duplicateField(String)
    case noMatch
    case ambiguousMatch
    case invalidCapture(name: String, value: String)
    case missingField(String)
    case invalidRenderedSegment(String)
}
