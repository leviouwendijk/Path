public extension StandardPath {
    func mappingSegment(
        at index: Int,
        _ transform: (PathSegment) -> PathSegment
    ) -> StandardPath {
        guard segments.indices.contains(index) else {
            return self
        }

        var copy = self
        copy.segments[index] = transform(
            copy.segments[index]
        )
        return copy
    }

    func mappingFirstSegment(
        _ transform: (PathSegment) -> PathSegment
    ) -> StandardPath {
        mappingSegment(
            at: 0,
            transform
        )
    }

    func mappingLastSegment(
        _ transform: (PathSegment) -> PathSegment
    ) -> StandardPath {
        guard !segments.isEmpty else {
            return self
        }

        return mappingSegment(
            at: segments.count - 1,
            transform
        )
    }

    mutating func mapSegment(
        at index: Int,
        _ transform: (PathSegment) -> PathSegment
    ) {
        guard segments.indices.contains(index) else {
            return
        }

        segments[index] = transform(
            segments[index]
        )
    }

    mutating func mapFirstSegment(
        _ transform: (PathSegment) -> PathSegment
    ) {
        mapSegment(
            at: 0,
            transform
        )
    }

    mutating func mapLastSegment(
        _ transform: (PathSegment) -> PathSegment
    ) {
        guard !segments.isEmpty else {
            return
        }

        mapSegment(
            at: segments.count - 1,
            transform
        )
    }
}

public extension StandardPath {
    func prefixedSegment(
        at index: Int,
        _ prefix: String?
    ) -> StandardPath {
        mappingSegment(
            at: index
        ) { $0.prefixed(prefix) }
    }

    func suffixedSegment(
        at index: Int,
        _ suffix: String?
    ) -> StandardPath {
        mappingSegment(
            at: index
        ) { $0.suffixed(suffix) }
    }

    func affixedSegment(
        at index: Int,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> StandardPath {
        mappingSegment(
            at: index
        ) {
            $0.affixed(
                prefix: prefix,
                suffix: suffix
            )
        }
    }

    func affixedSegment(
        at index: Int,
        _ affix: PathSegmentAffix?
    ) -> StandardPath {
        mappingSegment(
            at: index
        ) { $0.affixed(affix) }
    }

    func prefixedFirstSegment(
        _ prefix: String?
    ) -> StandardPath {
        mappingFirstSegment { $0.prefixed(prefix) }
    }

    func suffixedFirstSegment(
        _ suffix: String?
    ) -> StandardPath {
        mappingFirstSegment { $0.suffixed(suffix) }
    }

    func affixedFirstSegment(
        prefix: String? = nil,
        suffix: String? = nil
    ) -> StandardPath {
        mappingFirstSegment {
            $0.affixed(
                prefix: prefix,
                suffix: suffix
            )
        }
    }

    func affixedFirstSegment(
        _ affix: PathSegmentAffix?
    ) -> StandardPath {
        mappingFirstSegment { $0.affixed(affix) }
    }

    func prefixedLastSegment(
        _ prefix: String?
    ) -> StandardPath {
        mappingLastSegment { $0.prefixed(prefix) }
    }

    func suffixedLastSegment(
        _ suffix: String?
    ) -> StandardPath {
        mappingLastSegment { $0.suffixed(suffix) }
    }

    func affixedLastSegment(
        prefix: String? = nil,
        suffix: String? = nil
    ) -> StandardPath {
        mappingLastSegment {
            $0.affixed(
                prefix: prefix,
                suffix: suffix
            )
        }
    }

    func affixedLastSegment(
        _ affix: PathSegmentAffix?
    ) -> StandardPath {
        mappingLastSegment { $0.affixed(affix) }
    }
}

public extension StandardPath {
    mutating func prefixSegment(
        at index: Int,
        _ prefix: String?
    ) {
        mapSegment(
            at: index
        ) {
            var copy = $0
            copy.prefix(prefix)
            return copy
        }
    }

    mutating func suffixSegment(
        at index: Int,
        _ suffix: String?
    ) {
        mapSegment(
            at: index
        ) {
            var copy = $0
            copy.suffix(suffix)
            return copy
        }
    }

    mutating func affixSegment(
        at index: Int,
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        mapSegment(
            at: index
        ) {
            var copy = $0
            copy.affix(
                prefix: prefix,
                suffix: suffix
            )
            return copy
        }
    }

    mutating func affixSegment(
        at index: Int,
        _ affix: PathSegmentAffix?
    ) {
        mapSegment(
            at: index
        ) {
            var copy = $0
            copy.affix(affix)
            return copy
        }
    }

    mutating func prefixFirstSegment(
        _ prefix: String?
    ) {
        prefixSegment(
            at: 0,
            prefix
        )
    }

    mutating func suffixFirstSegment(
        _ suffix: String?
    ) {
        suffixSegment(
            at: 0,
            suffix
        )
    }

    mutating func affixFirstSegment(
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        affixSegment(
            at: 0,
            prefix: prefix,
            suffix: suffix
        )
    }

    mutating func affixFirstSegment(
        _ affix: PathSegmentAffix?
    ) {
        affixSegment(
            at: 0,
            affix
        )
    }

    mutating func prefixLastSegment(
        _ prefix: String?
    ) {
        guard !segments.isEmpty else {
            return
        }

        prefixSegment(
            at: segments.count - 1,
            prefix
        )
    }

    mutating func suffixLastSegment(
        _ suffix: String?
    ) {
        guard !segments.isEmpty else {
            return
        }

        suffixSegment(
            at: segments.count - 1,
            suffix
        )
    }

    mutating func affixLastSegment(
        prefix: String? = nil,
        suffix: String? = nil
    ) {
        guard !segments.isEmpty else {
            return
        }

        affixSegment(
            at: segments.count - 1,
            prefix: prefix,
            suffix: suffix
        )
    }

    mutating func affixLastSegment(
        _ affix: PathSegmentAffix?
    ) {
        guard !segments.isEmpty else {
            return
        }

        affixSegment(
            at: segments.count - 1,
            affix
        )
    }
}
