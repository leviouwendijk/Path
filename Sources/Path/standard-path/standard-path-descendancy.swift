extension StandardPath {
    public func descends(
        from root: StandardPath
    ) -> Bool {
        let normalized_root = PathNormalization.root(root)
        let normalized_self = PathNormalization.path(self)

        let root_segments = normalized_root.segments.map(\.value)
        let candidate_segments = normalized_self.segments.map(\.value)

        guard candidate_segments.count >= root_segments.count else {
            return false
        }

        let prefix = Array(
            candidate_segments.prefix(root_segments.count)
        )

        return prefix == root_segments
    }

    public func relative(
        to root: StandardPath
    ) -> StandardPath? {
        let normalized_root = PathNormalization.root(root)
        let normalized_self = PathNormalization.path(self)

        guard normalized_self.descends(from: normalized_root) else {
            return nil
        }

        let relative_segments = Array(
            normalized_self.segments.dropFirst(
                normalized_root.segments.count
            )
        )

        return StandardPath(
            relative_segments,
            filetype: normalized_self.filetype
        )
    }
}
