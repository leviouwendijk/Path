import FileTypes

public extension PathAccessController {
    func authorize(
        _ scopedPaths: [ScopedPath],
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> [AuthorizedPath] {
        try scopedPaths.map {
            try authorize(
                $0,
                rootIdentifier: rootIdentifier,
                type: type
            )
        }
    }

    func authorize(
        _ paths: [StandardPath],
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> [AuthorizedPath] {
        try paths.map {
            try authorize(
                $0,
                rootIdentifier: rootIdentifier,
                type: type
            )
        }
    }

    func authorize(
        _ rawPaths: [String],
        rootIdentifier: PathAccessRootIdentifier? = nil,
        filetype: AnyFileType? = nil,
        type: PathSegmentType? = nil
    ) throws -> [AuthorizedPath] {
        try rawPaths.map {
            try authorize(
                $0,
                rootIdentifier: rootIdentifier,
                filetype: filetype,
                type: type
            )
        }
    }
}
