import Foundation
import FileTypes

public struct PathSandbox: Sendable, Codable, Equatable, Hashable {
    public let root: StandardPath
    public let tree: PathTree

    public init(
        root: StandardPath
    ) throws {
        guard root.filetype == nil else {
            throw PathSandboxError.rootMustBeDirectory(root)
        }

        let normalized_root = PathNormalization.root(root)

        self.root = normalized_root
        self.tree = PathTree(root: normalized_root)
    }

    public func sandbox(
        _ path: StandardPath
    ) throws -> DescendantPath {
        let relative = try PathNormalization.relative(
            to: root,
            path
        )
        let absolute = try tree.appending(
            relative
        )

        return try DescendantPath(
            absolute,
            from: root
        )
    }

    public func sandbox(
        rawPath: String,
        filetype: AnyFileType? = nil
    ) throws -> DescendantPath {
        try sandbox(
            PathStrictRelativeNormalization.path(
                rawPath: rawPath,
                root: root,
                filetype: filetype
            )
        )
    }

    // public func sandbox(
    //     rawPath: String,
    //     filetype: AnyFileType? = nil
    // ) throws -> DescendantPath {
    //     try sandbox(
    //         StandardPath(
    //             rawPath: rawPath,
    //             filetype: filetype
    //         )
    //     )
    // }

    public func contains(
        _ path: StandardPath
    ) -> Bool {
        guard let descendant = try? sandbox(path) else {
            return false
        }

        return descendant.root == root
    }

    public func contains(
        _ path: DescendantPath
    ) -> Bool {
        path.root == root
    }
}

extension PathSandbox {
    // init overloads
    public init(
        inside root: StandardPath
    ) throws {
        try self.init(root: root)
    }

    public init(
        in root: StandardPath
    ) throws {
        try self.init(root: root)
    }
}
