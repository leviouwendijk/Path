import FileTypes

public extension PathSandbox {
    func sandbox(
        _ path: StandardPath,
        policy: PathAccessPolicy,
        type: PathSegmentType? = nil
    ) throws -> ScopedPath {
        let scoped = try sandbox(path)
        let evaluation = policy.evaluate(
            scoped,
            type: type
        )

        guard evaluation.isAllowed else {
            throw PathAccessError.denied(evaluation)
        }

        return scoped
    }

    func sandbox(
        rawPath: String,
        filetype: AnyFileType? = nil,
        policy: PathAccessPolicy,
        type: PathSegmentType? = nil
    ) throws -> ScopedPath {
        let scoped = try sandbox(
            rawPath: rawPath,
            filetype: filetype
        )
        let evaluation = policy.evaluate(
            scoped,
            type: type
        )

        guard evaluation.isAllowed else {
            throw PathAccessError.denied(evaluation)
        }

        return scoped
    }

    func contains(
        _ path: ScopedPath,
        policy: PathAccessPolicy,
        type: PathSegmentType? = nil
    ) -> Bool {
        guard contains(path) else {
            return false
        }

        return policy.allows(
            path,
            type: type
        )
    }
}
