public struct StandardPath: SegmentConcatenable {
    public var segments: [PathSegment]
    public var filetype: AnyFileType?
    
    public init(
        segments: [PathSegment],
        filetype: AnyFileType? = nil
    ) {
        self.segments = segments
        self.filetype = filetype
    }

    public init(
        _ segments: [PathSegment],
        filetype: AnyFileType? = nil
    ) {
        self.segments = segments
        self.filetype = filetype
    }
}

// variadic
extension StandardPath {
    public init(
        _ segments: [String],
        filetype: AnyFileType? = nil
    ) {
        self.segments = segments.map( { .init(value: $0, type: nil) } )
        self.filetype = filetype
    }

    public init(
        _ segments: String...,
        filetype: AnyFileType? = nil
    ) {
        self.segments = segments.map( { .init(value: $0, type: nil) } )
        self.filetype = filetype
    }
}

extension StandardPath {
    public mutating func appendingSegments(_ segments: [PathSegment]) -> Void {
        for s in segments {
            self.segments.append(s)
        }
    }

    public mutating func appendingSegments(_ strings: [String]) -> Void {
        let typed = strings.map { $0.pathSegment() }
        appendingSegments(typed)
    }

    public mutating func appendingSegments(_ strings: String...) -> Void {
        appendingSegments(strings)
    }

    public func merged(appending secondObject: StandardPath) -> StandardPath {
        var new = self
        new.appendingSegments(secondObject.segments)
        return new
    }

    // private func flattened() -> [PathSegment] {
    //     return self.segments.compactMap { $0 }
    // }
}
