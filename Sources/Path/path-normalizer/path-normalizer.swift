public struct PathNormalizer {
    public let root: StandardPath
    
    public init(
        root: StandardPath
    ) {
        self.root = PathNormalization.root(root)
    }

    public func relative(
        path: StandardPath
    ) throws -> StandardPath {
        return try PathNormalization.relative(to: root, path)
    }
}
