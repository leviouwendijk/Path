import Foundation

public enum PathSandboxError: Error, LocalizedError, Sendable, Equatable {
    case rootMustBeDirectory(StandardPath)
    case pathEscapesSandbox(
        path: StandardPath,
        root: StandardPath
    )
    /// The path passes through `link` and the policy is `.never`.
    case symlinkNotFollowed(
        path: StandardPath,
        link: String
    )
    /// `link` leads to `destination`, outside every installed root.
    case symlinkEscapesRoots(
        path: StandardPath,
        link: String,
        destination: String
    )
    case symlinkLoop(
        path: StandardPath
    )

    public var errorDescription: String? {
        switch self {
        case .rootMustBeDirectory(let root):
            return """
            PathSandbox root must be a directory, not a file: \
            \(root.render(as: .root, filetype: true))
            """

        case .pathEscapesSandbox(let path, let root):
            return """
            Path escapes sandbox. relative=\(path.render(as: .relative, filetype: true)) \
            root=\(root.render(as: .root, filetype: false))
            """

        case .symlinkNotFollowed(let path, let link):
            return """
            Path passes through a symbolic link, which is not followed: \
            \(path.render(as: .root, filetype: true)) (link \(link))
            """

        case .symlinkEscapesRoots(let path, let link, let destination):
            return """
            Symbolic link leads outside every root: \
            \(path.render(as: .root, filetype: true)) (link \(link) -> \(destination))
            """

        case .symlinkLoop(let path):
            return """
            Too many symbolic links: \(path.render(as: .root, filetype: true))
            """
        }
    }

    public var failureReason: String? {
        switch self {
        case .rootMustBeDirectory:
            return """
            A sandbox root must describe a directory boundary. \
            A file-typed root cannot safely scope descendants.
            """

        case .pathEscapesSandbox:
            return """
            The provided path contains traversal semantics that would move \
            outside the sandbox root after lexical normalization.
            """

        case .symlinkNotFollowed:
            return """
            The symlink policy is `never`: no path may pass through a link \
            below its root.
            """

        case .symlinkEscapesRoots:
            return """
            The symlink policy is `roots`: a link may only lead into an \
            installed root.
            """

        case .symlinkLoop:
            return """
            Following the path's links did not settle within the limit.
            """
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .rootMustBeDirectory:
            return """
            Pass a directory-shaped StandardPath as the root, with filetype == nil.
            """

        case .pathEscapesSandbox:
            return """
            Provide a path relative to the sandbox root that does not traverse above it.
            """

        case .symlinkNotFollowed, .symlinkEscapesRoots:
            return """
            Use the path the link points to, add its location as a root, or \
            change the symlink policy.
            """

        case .symlinkLoop:
            return """
            Remove the link cycle.
            """
        }
    }
}
