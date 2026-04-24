import Foundation

public enum PathTreeModelError: Error, LocalizedError, Sendable, Equatable {
    case emptyRelativePath
    case cannotMoveRoot
    case cannotMoveNodeIntoItself(
        StandardPath,
        StandardPath
    )
    case nodeNotFound(StandardPath)
    case destinationNotFound(StandardPath)
    case destinationIsFile(StandardPath)
    case duplicateNode(String)

    public var errorDescription: String? {
        switch self {
        case .emptyRelativePath:
            return "Path tree operation requires a non-empty relative path."

        case .cannotMoveRoot:
            return "Cannot move or rename the root of a PathTree."

        case .cannotMoveNodeIntoItself(let source, let destination):
            return """
            Cannot move path tree node into itself. \
            source=\(source.render(as: .relative, filetype: true)) \
            destination=\(destination.render(as: .relative, filetype: true))
            """

        case .nodeNotFound(let path):
            return "Path tree node not found: \(path.render(as: .relative, filetype: true))"

        case .destinationNotFound(let path):
            return "Path tree destination not found: \(path.render(as: .relative, filetype: true))"

        case .destinationIsFile(let path):
            return "Path tree destination is a file, not a directory: \(path.render(as: .relative, filetype: true))"

        case .duplicateNode(let component):
            return "Path tree already contains a node named: \(component)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .emptyRelativePath:
            return "The operation was asked to create or move an empty path."

        case .cannotMoveRoot:
            return "The tree root is the containment boundary, not a movable model node."

        case .cannotMoveNodeIntoItself:
            return "Moving a node under one of its own descendants would create a cycle."

        case .nodeNotFound:
            return "The source path does not exist in the in-memory path tree model."

        case .destinationNotFound:
            return "The destination path does not exist in the in-memory path tree model."

        case .destinationIsFile:
            return "Only directory nodes can contain child nodes."

        case .duplicateNode:
            return "Sibling nodes must have unique rendered components unless replacingExisting is true."
        }
    }
}
