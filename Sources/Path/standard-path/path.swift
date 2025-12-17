public typealias GenericPath = StandardPath

public struct StandardPath: SegmentConcatenable {
    public var segments: [PathSegment]
    
    public init(
        segments: [PathSegment]
    ) {
        self.segments = segments
    }

    public init(
        _ segments: [PathSegment]
    ) {
        self.segments = segments
    }

    public init(
        _ segments: [String]
    ) {
        self.segments = segments.map( { .init(value: $0, type: nil) } )
    }

    public init(
        _ segments: String...
    ) {
        self.segments = segments.map( { .init(value: $0, type: nil) } )
    }

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
