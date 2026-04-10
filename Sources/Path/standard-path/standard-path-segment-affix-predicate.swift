public extension StandardPath {
    func mappingAllSegments(
        _ transform: (PathSegment) -> PathSegment
    ) -> StandardPath {
        var copy = self
        copy.mapAllSegments(transform)
        return copy
    }

    func mappingSegments(
        where predicate: (PathSegment) -> Bool,
        _ transform: (PathSegment) -> PathSegment
    ) -> StandardPath {
        var copy = self
        copy.mapSegments(
            where: predicate,
            transform
        )
        return copy
    }

    mutating func mapAllSegments(
        _ transform: (PathSegment) -> PathSegment
    ) {
        guard !segments.isEmpty else {
            return
        }

        segments = segments.map(transform)
    }

    mutating func mapSegments(
        where predicate: (PathSegment) -> Bool,
        _ transform: (PathSegment) -> PathSegment
    ) {
        guard !segments.isEmpty else {
            return
        }

        segments = segments.map { segment in
            guard predicate(segment) else {
                return segment
            }

            return transform(segment)
        }
    }
}

public extension StandardPath {
    func prefixedAllSegments(
        _ prefix: String?
    ) -> StandardPath {
        mappingAllSegments {
            $0.prefixed(prefix)
        }
    }

    func suffixedAllSegments(
        _ suffix: String?
    ) -> StandardPath {
        mappingAllSegments {
            $0.suffixed(suffix)
        }
    }

    func affixedAllSegments(
        prefix: String? = nil,
        suffix: String? = nil
    ) -> StandardPath {
        mappingAllSegments {
            $0.affixed(
                prefix: prefix,
                suffix: suffix
            )
        }
    }

    func affixedAllSegments(
        _ affix: PathSegmentAffix?
    ) -> StandardPath {
        mappingAllSegments {
            $0.affixed(affix)
        }
    }
}

public extension StandardPath {
    func prefixedSegments(
        matching predicate: (PathSegment) -> Bool,
        _ prefix: String?
    ) -> StandardPath {
        mappingSegments(
            where: predicate
        ) {
            $0.prefixed(prefix)
        }
    }

    func suffixedSegments(
        matching predicate: (PathSegment) -> Bool,
        _ suffix: String?
    ) -> StandardPath {
        mappingSegments(
            where: predicate
        ) {
            $0.suffixed(suffix)
        }
    }

    func affixedSegments(
        matching predicate: (PathSegment) -> Bool,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> StandardPath {
        mappingSegments(
            where: predicate
        ) {
            $0.affixed(
                prefix: prefix,
                suffix: suffix
            )
        }
    }

    func affixedSegments(
        matching predicate: (PathSegment) -> Bool,
        _ affix: PathSegmentAffix?
    ) -> StandardPath {
        mappingSegments(
            where: predicate
        ) {
            $0.affixed(affix)
        }
    }
}

public extension StandardPath {
    mutating func prefixAllSegments(
        _ prefix: String?
    ) {
        mapAllSegments {
            var copy = $0
            copy.prefix(prefix)
            return copy
        }
    }

    mutating func suffixAllSegments(
        _ suffix: String?
    ) {
        mapAllSegments {
            var copy = $0
            copy.suffix(suffix)
            return copy
        }
    }

    mutating func affixAllSegments(
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        mapAllSegments {
            var copy = $0
            copy.affix(
                prefix: prefix,
                suffix: suffix
            )
            return copy
        }
    }

    mutating func affixAllSegments(
        _ affix: PathSegmentAffix?
    ) {
        mapAllSegments {
            var copy = $0
            copy.affix(affix)
            return copy
        }
    }
}

public extension StandardPath {
    mutating func prefixSegments(
        matching predicate: (PathSegment) -> Bool,
        _ prefix: String?
    ) {
        mapSegments(
            where: predicate
        ) {
            var copy = $0
            copy.prefix(prefix)
            return copy
        }
    }

    mutating func suffixSegments(
        matching predicate: (PathSegment) -> Bool,
        _ suffix: String?
    ) {
        mapSegments(
            where: predicate
        ) {
            var copy = $0
            copy.suffix(suffix)
            return copy
        }
    }

    mutating func affixSegments(
        matching predicate: (PathSegment) -> Bool,
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        mapSegments(
            where: predicate
        ) {
            var copy = $0
            copy.affix(
                prefix: prefix,
                suffix: suffix
            )
            return copy
        }
    }

    mutating func affixSegments(
        matching predicate: (PathSegment) -> Bool,
        _ affix: PathSegmentAffix?
    ) {
        mapSegments(
            where: predicate
        ) {
            var copy = $0
            copy.affix(affix)
            return copy
        }
    }
}
