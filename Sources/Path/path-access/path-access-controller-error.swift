import Foundation

public enum PathAccessControllerError: Error, LocalizedError, Sendable, Equatable {
    case rootNotFound(PathAccessRootIdentifier)
    case defaultRootUnavailable
    case scopedPathRootMismatch(
        rootIdentifier: PathAccessRootIdentifier,
        expectedRoot: StandardPath,
        actualRoot: StandardPath
    )

    public var errorDescription: String? {
        switch self {
        case .rootNotFound(let rootIdentifier):
            return "No path access root exists for identifier '\(rootIdentifier.rawValue)'."

        case .defaultRootUnavailable:
            return "No default path access root is configured."

        case .scopedPathRootMismatch(let rootIdentifier, let expectedRoot, let actualRoot):
            return """
            Scoped path root mismatch for root '\(rootIdentifier.rawValue)'. \
            Expected '\(expectedRoot.render(as: .root, filetype: false))', \
            got '\(actualRoot.render(as: .root, filetype: false))'.
            """
        }
    }
}
