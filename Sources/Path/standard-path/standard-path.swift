public struct StandardPath: SegmentConcatenable {
    public var segments: [PathSegment]
    public var filetype: AnyFileType?

    public init(
        segments: [PathSegment],
        filetype: AnyFileType? = nil
    ) {
        self.segments = Self.validated(segments)
        self.filetype = filetype
    }

    public init(
        _ segments: [PathSegment],
        filetype: AnyFileType? = nil
    ) {
        self.init(
            segments: segments,
            filetype: filetype
        )
    }

    public init(
        _ segments: [String],
        filetype: AnyFileType? = nil
    ) {
        self.init(
            segments: segments.map { PathSegment($0) },
            filetype: filetype
        )
    }

    public init(
        _ segments: String...,
        filetype: AnyFileType? = nil
    ) {
        self.init(
            segments,
            filetype: filetype
        )
    }

    public init(
        rawPath: String,
        filetype: AnyFileType? = nil
    ) {
        self.init(
            Self.normalizedRawPathComponents(rawPath),
            filetype: filetype
        )
    }
}

public extension StandardPath {
    mutating func appendingSegments(
        _ segments: [PathSegment]
    ) {
        self.segments.append(
            contentsOf: Self.validated(segments)
        )
    }

    mutating func appendingSegments(
        _ strings: [String]
    ) {
        appendingSegments(
            strings.map { PathSegment($0) }
        )
    }

    mutating func appendingSegments(
        _ strings: String...
    ) {
        appendingSegments(strings)
    }

    func merged(
        appending secondObject: StandardPath
    ) -> StandardPath {
        var new = self
        new.appendingSegments(secondObject.segments)
        return new
    }
}

public extension StandardPath {
    static func validated(
        _ segments: [PathSegment]
    ) -> [PathSegment] {
        segments.map(validate)
    }

    static func normalizedRawPathComponents(
        _ rawPath: String
    ) -> [String] {
        let parts = rawPath
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)

        return normalize(parts)
    }
}

private extension StandardPath {
    static func validate(
        _ segment: PathSegment
    ) -> PathSegment {
        precondition(
            !segment.value.isEmpty,
            "Path segments cannot be empty."
        )

        precondition(
            !segment.value.contains("/"),
            "Path segments must be atomic. Use StandardPath(rawPath:) for slash-bearing input."
        )

        precondition(
            segment.value != ".",
            "Stored StandardPath segments cannot contain '.'. Normalize first."
        )

        precondition(
            segment.value != "..",
            "Stored StandardPath segments cannot contain '..'. Normalize first."
        )

        return segment
    }

    static func normalize(
        _ raw: [String]
    ) -> [String] {
        var out: [String] = []
        out.reserveCapacity(raw.count)

        for part in raw {
            switch part {
            case "", ".":
                continue

            case "..":
                if !out.isEmpty {
                    out.removeLast()
                }

            default:
                out.append(part)
            }
        }

        return out
    }
}

// public struct StandardPath: SegmentConcatenable {
//     public var segments: [PathSegment]
//     public var filetype: AnyFileType?
    
//     public init(
//         segments: [PathSegment],
//         filetype: AnyFileType? = nil
//     ) {
//         self.segments = segments
//         self.filetype = filetype
//     }

//     public init(
//         _ segments: [PathSegment],
//         filetype: AnyFileType? = nil
//     ) {
//         self.segments = segments
//         self.filetype = filetype
//     }
// }

// // variadic
// extension StandardPath {
//     public init(
//         _ segments: [String],
//         filetype: AnyFileType? = nil
//     ) {
//         self.segments = segments.map( { .init(value: $0, type: nil) } )
//         self.filetype = filetype
//     }

//     public init(
//         _ segments: String...,
//         filetype: AnyFileType? = nil
//     ) {
//         self.segments = segments.map( { .init(value: $0, type: nil) } )
//         self.filetype = filetype
//     }
// }

// extension StandardPath {
//     public mutating func appendingSegments(_ segments: [PathSegment]) -> Void {
//         for s in segments {
//             self.segments.append(s)
//         }
//     }

//     public mutating func appendingSegments(_ strings: [String]) -> Void {
//         let typed = strings.map { $0.pathSegment() }
//         appendingSegments(typed)
//     }

//     public mutating func appendingSegments(_ strings: String...) -> Void {
//         appendingSegments(strings)
//     }

//     public func merged(appending secondObject: StandardPath) -> StandardPath {
//         var new = self
//         new.appendingSegments(secondObject.segments)
//         return new
//     }

//     // private func flattened() -> [PathSegment] {
//     //     return self.segments.compactMap { $0 }
//     // }
// }
