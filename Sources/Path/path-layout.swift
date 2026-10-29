import Foundation

public enum PathLayoutAlignment: Sendable, Equatable {
    /// Match the full supplied path.
    case exact
    /// Match a terminal path structure after any number of preceding segments.
    case suffix
    /// Find one exact sequence of anchor segments and match immediately after it.
    case after([String])
}

/// Pure, composable path structure. It does not resolve roots or authorize access.
public struct PathLayout: Sendable {
    public let components: [PathLayoutComponent]

    public init(_ components: [PathLayoutComponent]) {
        self.components = components
    }

    public init(_ components: PathLayoutComponent...) {
        self.init(components)
    }
}

public struct PathLayoutComponent: Sendable {
    internal enum Kind: Sendable {
        case literal(String)
        case capture(PathLayoutCodec)
        case remainder(String)
        case file(PathLayoutCodec, ext: String)
        case include(PathLayout)
    }

    internal let kind: Kind

    private init(_ kind: Kind) {
        self.kind = kind
    }

    public static func literal(_ value: String) -> Self {
        .init(.literal(value))
    }

    public static func include(_ layout: PathLayout) -> Self {
        .init(.include(layout))
    }

    public static func capture<Value: LosslessStringConvertible & Sendable>(
        _ field: PathField<Value>
    ) -> Self {
        capture(
            field,
            decode: { raw in
                guard let value = Value(raw) else {
                    throw PathLayoutError.invalidCapture(name: field.name, value: raw)
                }
                return value
            },
            encode: { String(describing: $0) }
        )
    }

    /// Custom decoding permits construction of validated domain values.
    public static func capture<Value: Sendable>(
        _ field: PathField<Value>,
        decode: @escaping @Sendable (String) throws -> Value,
        encode: @escaping @Sendable (Value) throws -> String
    ) -> Self {
        .init(.capture(.init(field, decode: decode, encode: encode)))
    }

    /// Capture zero or more directory components, including in the middle.
    public static func remainder(_ field: PathField<[String]>) -> Self {
        .init(.remainder(field.name))
    }

    /// Capture the stem of a terminal file with an exact extension.
    public static func file<Value: LosslessStringConvertible & Sendable>(
        stem field: PathField<Value>,
        extension ext: String
    ) -> Self {
        file(
            stem: field,
            extension: ext,
            decode: { raw in
                guard let value = Value(raw) else {
                    throw PathLayoutError.invalidCapture(name: field.name, value: raw)
                }
                return value
            },
            encode: { String(describing: $0) }
        )
    }

    public static func file<Value: Sendable>(
        stem field: PathField<Value>,
        extension ext: String,
        decode: @escaping @Sendable (String) throws -> Value,
        encode: @escaping @Sendable (Value) throws -> String
    ) -> Self {
        .init(.file(.init(field, decode: decode, encode: encode), ext: ext))
    }
}

internal struct PathLayoutCodec: Sendable {
    let name: String
    let decode: @Sendable (String) throws -> any Sendable
    let encode: @Sendable (any Sendable) throws -> String

    init<Value: Sendable>(
        _ field: PathField<Value>,
        decode: @escaping @Sendable (String) throws -> Value,
        encode: @escaping @Sendable (Value) throws -> String
    ) {
        name = field.name
        self.decode = { try decode($0) }
        self.encode = { value in
            guard let typed = value as? Value else {
                throw PathLayoutError.missingField(field.name)
            }
            return try encode(typed)
        }
    }
}

public extension PathLayout {
    func decode(
        _ path: StandardPath,
        alignment: PathLayoutAlignment = .exact
    ) throws -> PathLayoutMatch {
        let layout = try flattenedAndValidated()
        let segments = Self.renderedComponents(path)
        let starts: [Int]

        switch alignment {
        case .exact:
            starts = [0]
        case .suffix:
            starts = Array(0...segments.count)
        case .after(let anchor):
            guard !anchor.isEmpty, anchor.allSatisfy(Self.isValidSegment) else {
                throw PathLayoutError.invalidLayout("Anchor must be nonempty, atomic segments")
            }
            let positions = (0...segments.count).compactMap { index -> Int? in
                guard index + anchor.count <= segments.count else { return nil }
                return Array(segments[index..<(index + anchor.count)]) == anchor
                    ? index + anchor.count : nil
            }
            guard positions.count <= 1 else { throw PathLayoutError.ambiguousMatch }
            starts = positions
        }

        var matches: [PathLayoutMatch] = []
        var firstFailure: PathLayoutError?
        for start in starts {
            let found = Self.walk(
                layout, segments, at: 0, from: start,
                origin: start, values: .init(), captures: [:],
                firstFailure: &firstFailure
            )
            matches.append(contentsOf: found)
            if matches.count > 1 { throw PathLayoutError.ambiguousMatch }
        }
        guard let match = matches.first else {
            throw firstFailure ?? .noMatch
        }
        return match
    }

    func render(_ values: PathLayoutValues) throws -> StandardPath {
        let layout = try flattenedAndValidated()
        var rendered: [PathSegment] = []
        for item in layout {
            switch item {
            case .literal(let literal):
                rendered.append(PathSegment(literal))
            case .capture(let field):
                guard let value = values.storage[field.name] else {
                    throw PathLayoutError.missingField(field.name)
                }
                let segment = try field.encode(value)
                try Self.requireSegment(segment)
                rendered.append(PathSegment(segment))
            case .remainder(let name):
                guard let segments = values.storage[name] as? [String] else {
                    throw PathLayoutError.missingField(name)
                }
                for segment in segments {
                    try Self.requireSegment(segment)
                    rendered.append(PathSegment(segment))
                }
            case .file(let field, let ext):
                guard let value = values.storage[field.name] else {
                    throw PathLayoutError.missingField(field.name)
                }
                let stem = try field.encode(value)
                try Self.requireSegment(stem)
                rendered.append(PathSegment(stem + "." + ext, .file))
            case .include:
                throw PathLayoutError.invalidLayout("Unflattened include")
            }
        }
        return StandardPath(segments: rendered)
    }
}

private extension PathLayout {
    typealias Kind = PathLayoutComponent.Kind

    func flattenedAndValidated() throws -> [Kind] {
        var result: [Kind] = []
        func append(_ components: [PathLayoutComponent]) {
            for component in components {
                if case .include(let layout) = component.kind {
                    append(layout.components)
                } else {
                    result.append(component.kind)
                }
            }
        }
        append(components)
        var names = Set<String>()
        var remainderCount = 0
        for (index, component) in result.enumerated() {
            switch component {
            case .literal(let value):
                try Self.requireSegment(value)
            case .capture(let field), .file(let field, _):
                guard !field.name.isEmpty else {
                    throw PathLayoutError.invalidLayout("Empty capture name")
                }
                guard names.insert(field.name).inserted else {
                    throw PathLayoutError.duplicateField(field.name)
                }
            case .remainder(let name):
                guard !name.isEmpty else {
                    throw PathLayoutError.invalidLayout("Empty remainder name")
                }
                guard names.insert(name).inserted else {
                    throw PathLayoutError.duplicateField(name)
                }
                remainderCount += 1
                guard remainderCount == 1 else {
                    throw PathLayoutError.invalidLayout("At most one variable-length region")
                }
            case .include:
                throw PathLayoutError.invalidLayout("Unflattened include")
            }
            if case .file(_, let ext) = component {
                guard index == result.count - 1,
                    !ext.isEmpty, !ext.contains("/"), !ext.contains(".")
                else { throw PathLayoutError.invalidLayout("Invalid terminal file extension") }
            }
        }
        return result
    }

    static func renderedComponents(_ path: StandardPath) -> [String] {
        var values = path.segments.map(\.value)
        if let filetype = path.filetype {
            if let last = values.popLast() {
                values.append(last + filetype.component)
            } else {
                values.append(filetype.component)
            }
        }
        return values
    }

    static func isValidSegment(_ value: String) -> Bool {
        !value.isEmpty && value != "." && value != ".." && !value.contains("/")
    }

    static func requireSegment(_ value: String) throws {
        guard isValidSegment(value) else {
            throw PathLayoutError.invalidRenderedSegment(value)
        }
    }

    static func walk(
        _ layout: [Kind], _ path: [String], at index: Int,
        from cursor: Int, origin: Int,
        values: PathLayoutValues, captures: [String: PathLayoutCapture],
        firstFailure: inout PathLayoutError?
    ) -> [PathLayoutMatch] {
        if index == layout.count {
            guard cursor == path.count else { return [] }
            return [.init(values: values, captures: captures, matchedRange: origin..<cursor)]
        }

        switch layout[index] {
        case .literal(let literal):
            guard cursor < path.count, path[cursor] == literal else { return [] }
            return walk(layout, path, at: index + 1, from: cursor + 1,
                        origin: origin, values: values, captures: captures,
                        firstFailure: &firstFailure)

        case .capture(let field), .file(let field, _):
            guard cursor < path.count else { return [] }
            var raw = path[cursor]
            if case .file(_, let ext) = layout[index] {
                let suffix = "." + ext
                guard raw.hasSuffix(suffix), raw.count > suffix.count else { return [] }
                raw = String(raw.dropLast(suffix.count))
            }
            do {
                let value = try field.decode(raw)
                var next = values
                next.storage[field.name] = value
                var sources = captures
                sources[field.name] = .init(segments: [path[cursor]], range: cursor..<(cursor + 1))
                return walk(layout, path, at: index + 1, from: cursor + 1,
                            origin: origin, values: next, captures: sources,
                            firstFailure: &firstFailure)
            } catch {
                if firstFailure == nil {
                    firstFailure = .invalidCapture(name: field.name, value: raw)
                }
                return []
            }

        case .remainder(let name):
            var found: [PathLayoutMatch] = []
            for end in cursor...path.count {
                var next = values
                next.storage[name] = Array(path[cursor..<end])
                var sources = captures
                sources[name] = .init(segments: Array(path[cursor..<end]), range: cursor..<end)
                found.append(contentsOf: walk(layout, path, at: index + 1,
                    from: end, origin: origin, values: next, captures: sources,
                    firstFailure: &firstFailure))
                if found.count > 1 { break }
            }
            return found

        case .include:
            return []
        }
    }
}
