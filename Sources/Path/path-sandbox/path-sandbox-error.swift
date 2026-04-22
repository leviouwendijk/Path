import Foundation

public enum PathSandboxError: Error, LocalizedError, Sendable, Equatable {
    case rootMustBeDirectory(StandardPath)
    case pathEscapesSandbox(
        path: StandardPath,
        root: StandardPath
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
        }
    }
}
