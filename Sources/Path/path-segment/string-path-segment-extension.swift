extension String {
    public func pathSegment(type: PathSegmentType? = nil) -> PathSegment {
        return .init(value: self, type: type)        
    }
}
