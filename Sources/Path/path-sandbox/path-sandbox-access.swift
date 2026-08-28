import FileTypes

public extension PathSandbox {
    func sandbox(
        _ path: StandardPath,
        policy: PathAccessPolicy,
        type: PathSegmentType? = nil
    ) throws -> DescendantPath {
        let descendant = try sandbox(path)
        let evaluation = policy.evaluate(
            descendant,
            type: type
        )

        guard evaluation.isAllowed else {
            throw PathAccessError.denied(evaluation)
        }

        return descendant
    }

    func sandbox(
        rawPath: String,
        filetype: AnyFileType? = nil,
        policy: PathAccessPolicy,
        type: PathSegmentType? = nil
    ) throws -> DescendantPath {
        let descendant = try sandbox(
            rawPath: rawPath,
            filetype: filetype
        )
        let evaluation = policy.evaluate(
            descendant,
            type: type
        )

        guard evaluation.isAllowed else {
            throw PathAccessError.denied(evaluation)
        }

        return descendant
    }

    func contains(
        _ path: DescendantPath,
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
