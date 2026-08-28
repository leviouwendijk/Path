import Foundation

public enum DescendantPathError:
    Error,
    LocalizedError,
    Sendable,
    Equatable
{
    case rootMustBeDirectory(StandardPath)
    case notDescendant(
        path: StandardPath,
        root: StandardPath
    )

    public var errorDescription: String? {
        switch self {
        case .rootMustBeDirectory(let root):
            return "Descendant root must be a directory: \(root.render(as: .root, filetype: true))"

        case .notDescendant(let path, let root):
            return "Path is not a descendant of root: \(path.render(as: .root, filetype: true)) from \(root.render(as: .root, filetype: false))"
        }
    }
}
