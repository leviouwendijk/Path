import Foundation
import FileTypes

public struct PathSandbox: Sendable, Codable, Equatable {
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
    ) throws -> ScopedPath {
        let relative = try PathNormalization.relative(
            to: root,
            path
        )

        let absolute = try tree.appending(relative)

        guard tree.descends(absolute) else {
            throw PathSandboxError.pathEscapesSandbox(
                path: path,
                root: root
            )
        }

        return ScopedPath(
            root: root,
            relative: relative
        )
    }

    public func sandbox(
        rawPath: String,
        filetype: AnyFileType? = nil
    ) throws -> ScopedPath {
        try sandbox(
            StandardPath(
                rawPath: rawPath,
                filetype: filetype
            )
        )
    }

    public func contains(
        _ path: StandardPath
    ) -> Bool {
        guard let scoped = try? sandbox(path) else {
            return false
        }

        return scoped.root == root
    }

    public func contains(
        _ path: ScopedPath
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
