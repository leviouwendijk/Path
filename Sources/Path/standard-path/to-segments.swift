public protocol StandardPathComponent: Sendable {
    func toPathSegments() -> [PathSegment]
}

extension String: StandardPathComponent {
    public func toPathSegments() -> [PathSegment] {
        [self.pathSegment()]
    }
}

extension PathSegment: StandardPathComponent {
    public func toPathSegments() -> [PathSegment] {
        [self]
    }
}

extension StandardPath: StandardPathComponent {
    public func toPathSegments() -> [PathSegment] {
        self.segments
    }
}
