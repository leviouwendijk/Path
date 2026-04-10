public extension StandardPath {
    func mappingAllSegmentsIndexed(
        _ transform: (Int, PathSegment) -> PathSegment
    ) -> StandardPath {
        var copy = self
        copy.mapAllSegmentsIndexed(transform)
        return copy
    }

    func mappingSegments(
        where predicate: (Int, PathSegment) -> Bool,
        _ transform: (Int, PathSegment) -> PathSegment
    ) -> StandardPath {
        var copy = self
        copy.mapSegments(
            where: predicate,
            transform
        )
        return copy
    }

    mutating func mapAllSegmentsIndexed(
        _ transform: (Int, PathSegment) -> PathSegment
    ) {
        guard !segments.isEmpty else {
            return
        }

        segments = segments.enumerated().map { index, segment in
            transform(index, segment)
        }
    }

    mutating func mapSegments(
        where predicate: (Int, PathSegment) -> Bool,
        _ transform: (Int, PathSegment) -> PathSegment
    ) {
        guard !segments.isEmpty else {
            return
        }

        segments = segments.enumerated().map { index, segment in
            guard predicate(index, segment) else {
                return segment
            }

            return transform(index, segment)
        }
    }
}

public extension StandardPath {
    func prefixedSegments(
        where predicate: (Int, PathSegment) -> Bool,
        _ prefix: String?
    ) -> StandardPath {
        mappingSegments(
            where: predicate
        ) { _, segment in
            segment.prefixed(prefix)
        }
    }

    func suffixedSegments(
        where predicate: (Int, PathSegment) -> Bool,
        _ suffix: String?
    ) -> StandardPath {
        mappingSegments(
            where: predicate
        ) { _, segment in
            segment.suffixed(suffix)
        }
    }

    func affixedSegments(
        where predicate: (Int, PathSegment) -> Bool,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> StandardPath {
        mappingSegments(
            where: predicate
        ) { _, segment in
            segment.affixed(
                prefix: prefix,
                suffix: suffix
            )
        }
    }

    func affixedSegments(
        where predicate: (Int, PathSegment) -> Bool,
        _ affix: PathSegmentAffix?
    ) -> StandardPath {
        mappingSegments(
            where: predicate
        ) { _, segment in
            segment.affixed(affix)
        }
    }
}

public extension StandardPath {
    mutating func prefixSegments(
        where predicate: (Int, PathSegment) -> Bool,
        _ prefix: String?
    ) {
        mapSegments(
            where: predicate
        ) { _, segment in
            var copy = segment
            copy.prefix(prefix)
            return copy
        }
    }

    mutating func suffixSegments(
        where predicate: (Int, PathSegment) -> Bool,
        _ suffix: String?
    ) {
        mapSegments(
            where: predicate
        ) { _, segment in
            var copy = segment
            copy.suffix(suffix)
            return copy
        }
    }

    mutating func affixSegments(
        where predicate: (Int, PathSegment) -> Bool,
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        mapSegments(
            where: predicate
        ) { _, segment in
            var copy = segment
            copy.affix(
                prefix: prefix,
                suffix: suffix
            )
            return copy
        }
    }

    mutating func affixSegments(
        where predicate: (Int, PathSegment) -> Bool,
        _ affix: PathSegmentAffix?
    ) {
        mapSegments(
            where: predicate
        ) { _, segment in
            var copy = segment
            copy.affix(affix)
            return copy
        }
    }
}
