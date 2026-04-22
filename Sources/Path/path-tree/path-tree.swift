public struct PathTree: Sendable, Codable, Equatable {
    public let root: StandardPath

    public init(
        root: StandardPath
    ) {
        self.root = PathNormalization.root(root)
    }

    public func descends(
        _ candidate: StandardPath
    ) -> Bool {
        PathNormalization.path(candidate)
            .descends(from: root)
    }

    public func relative(
        _ candidate: StandardPath
    ) -> StandardPath? {
        PathNormalization.path(candidate)
            .relative(to: root)
    }

    public func require_relative(
        _ candidate: StandardPath
    ) throws -> StandardPath {
        guard let relative = relative(candidate) else {
            throw PathSandboxError.pathEscapesSandbox(
                path: candidate,
                root: root
            )
        }

        return relative
    }

    public func contains(
        segment: String
    ) -> Bool {
        root.segments.contains {
            $0.value == segment
        }
    }

    public func contains(
        segment: PathSegment
    ) -> Bool {
        root.segments.contains(segment)
    }

    public func appending(
        _ relative: StandardPath
    ) throws -> StandardPath {
        let normalized_relative = try PathNormalization.relative(
            to: root,
            relative
        )

        return StandardPath(
            from: root,
            normalized_relative.segments.map(\.value),
            filetype: normalized_relative.filetype
        )
    }
}

public extension PathTree {
    static func descends(
        from root: StandardPath,
        _ candidate: StandardPath
    ) -> Bool {
        PathTree(root: root)
            .descends(candidate)
    }

    static func relative(
        from root: StandardPath,
        _ candidate: StandardPath
    ) -> StandardPath? {
        PathTree(root: root)
            .relative(candidate)
    }
}
