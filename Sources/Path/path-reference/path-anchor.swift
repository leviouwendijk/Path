import Foundation

public enum PathAnchor: Sendable, Equatable {
    case root
    case home
    case cwd
    case directoryURL(URL)
    case fileURL(URL)
    case directoryPath(StandardPath)
    case filePath(StandardPath)

    public var directory_url: URL {
        switch self {
        case .root:
            return StandardPath.root.directory_url

        case .home:
            return StandardPath.home.directory_url

        case .cwd:
            return StandardPath.cwd.directory_url

        case .directoryURL(let url):
            return url.standardizedFileURL

        case .fileURL(let url):
            return url.standardizedFileURL
                .deletingLastPathComponent()

        case .directoryPath(let path):
            return path.directory_url

        case .filePath(let path):
            return path.root_url
                .deletingLastPathComponent()
        }
    }
}

@available(*, message: "use PathAnchor")
public typealias PathResolveBase = PathAnchor
