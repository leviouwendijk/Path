import Foundation

public struct PathSandbox: Sendable, Codable, Equatable {
    public let root: StandardPath

    public init(
        root: StandardPath
    ) throws {
        guard root.filetype == nil else {
            throw PathSandboxError.rootMustBeDirectory(root)
        }

        self.root = PathNormalization.root(root)
    }

    public func sandbox(
        _ path: StandardPath
    ) throws -> ScopedPath {
        let relative = try PathNormalization.relative(to: root, path)

        let absolute = StandardPath(
            from: root,
            relative.segments.map(\.value),
            filetype: relative.filetype
        )

        let tree = PathTree(root: root)

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
