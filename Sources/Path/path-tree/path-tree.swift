public struct PathTree {
    public let root: StandardPath
    
    public init(
        root: StandardPath
    ) {
        self.root = PathNormalization.root(root)
    }

    public func descends(
        _ candidate: StandardPath
    ) -> Bool {
        let root_segments = root.segments.map(\.value)
        let candidate_segments = candidate.segments.map(\.value)

        guard candidate_segments.count >= root_segments.count else {
            return false
        }

        let prefix = Array(
            candidate_segments.prefix(
                root_segments.count
            )
        )

        return (prefix == root_segments)
    }
}

extension PathTree {
    public static func descends(
        from root: StandardPath,
        _ candidate: StandardPath
    ) -> Bool {
        let path_tree = PathTree(root: root)
        return path_tree.descends(candidate)
    }
}
