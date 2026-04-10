public struct PathSegmentAffix: Sendable, Codable, Equatable {
    public var prefix: String?
    public var suffix: String?

    public init(
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        if let prefix {
            Self.validate(prefix)
        }

        if let suffix {
            Self.validate(suffix)
        }

        self.prefix = prefix
        self.suffix = suffix
    }

    public var isEmpty: Bool {
        prefix == nil && suffix == nil
    }

    public func applied(
        to segment: PathSegment
    ) -> PathSegment {
        var copy = segment
        copy.affix(self)
        return copy
    }
}

public extension PathSegmentAffix {
    static func prefix(
        _ prefix: String?
    ) -> Self {
        Self(prefix: prefix)
    }

    static func suffix(
        _ suffix: String?
    ) -> Self {
        Self(suffix: suffix)
    }
}

public extension PathSegment {
    func prefixed(
        _ prefix: String?
    ) -> PathSegment {
        affixed(
            prefix: prefix,
            suffix: nil
        )
    }

    func suffixed(
        _ suffix: String?
    ) -> PathSegment {
        affixed(
            prefix: nil,
            suffix: suffix
        )
    }

    func affixed(
        prefix: String? = nil,
        suffix: String? = nil
    ) -> PathSegment {
        var copy = self
        copy.affix(
            prefix: prefix,
            suffix: suffix
        )
        return copy
    }

    func affixed(
        _ affix: PathSegmentAffix?
    ) -> PathSegment {
        guard let affix else {
            return self
        }

        return affixed(
            prefix: affix.prefix,
            suffix: affix.suffix
        )
    }

    mutating func prefix(
        _ prefix: String?
    ) {
        affix(
            prefix: prefix,
            suffix: nil
        )
    }

    mutating func suffix(
        _ suffix: String?
    ) {
        affix(
            prefix: nil,
            suffix: suffix
        )
    }

    mutating func affix(
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        if let prefix {
            PathSegmentAffix.validate(prefix)
            value = prefix + value
        }

        if let suffix {
            PathSegmentAffix.validate(suffix)
            value += suffix
        }

        Self.validateFinalValue(value)
    }

    mutating func affix(
        _ affix: PathSegmentAffix?
    ) {
        guard let affix else {
            return
        }

        self.affix(
            prefix: affix.prefix,
            suffix: affix.suffix
        )
    }
}

public extension PathSegmentAffix {
    static func validate(
        _ value: String
    ) {
        precondition(
            !value.contains("/"),
            "Path segment affixes cannot contain '/'."
        )
    }
}

private extension PathSegment {
    static func validateFinalValue(
        _ value: String
    ) {
        precondition(
            !value.isEmpty,
            "Affixed path segment cannot be empty."
        )

        precondition(
            !value.contains("/"),
            "Affixed path segment cannot contain '/'."
        )

        precondition(
            value != ".",
            "Affixed path segment cannot be '.'."
        )

        precondition(
            value != "..",
            "Affixed path segment cannot be '..'."
        )
    }
}
