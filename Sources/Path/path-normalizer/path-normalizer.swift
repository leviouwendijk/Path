public struct PathNormalizer {
    public let root: StandardPath

    public init(
        root: StandardPath
    ) {
        self.root = PathNormalization.root(root)
    }

    public func path(
        _ path: StandardPath
    ) -> StandardPath {
        PathNormalization.path(path)
    }

    public func relative(
        path: StandardPath
    ) throws -> StandardPath {
        try PathNormalization.relative(
            to: root,
            path
        )
    }
}
