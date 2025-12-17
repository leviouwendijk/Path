public struct PathSegment: PathSegmentable {
    public var value: String
    public var type: ProjectPathSegmentType?
    
    public init(
        value: String,
        type: ProjectPathSegmentType? = nil
    ) {
        self.value = value
        self.type = type
    }

    public init(
        _ value: String,
        _ type: ProjectPathSegmentType? = nil
    ) {
        self.value = value
        self.type = type
    }
}

