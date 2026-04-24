import Foundation
import FileTypes

public extension PathAccessController {
    func authorize(
        _ url: URL,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> AuthorizedPath {
        let root = try root(
            identifier: rootIdentifier
        )
        let scopedPath = try root.scope.scope(
            url,
            type: type
        )

        return try authorize(
            scopedPath,
            rootIdentifier: root.id,
            type: type
        )
    }

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
        _ urls: [URL],
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> [AuthorizedPath] {
        try urls.map {
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
