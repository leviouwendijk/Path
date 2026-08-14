import Foundation

public struct PathWalkEntry: Sendable, Codable, Equatable {
    public let url: URL
    public let absolutePath: StandardPath
    public let relativePath: StandardPath
    public let depth: Int
    public let type: PathSegmentType

    public init(
        url: URL,
        absolutePath: StandardPath,
        relativePath: StandardPath,
        depth: Int,
        type: PathSegmentType
    ) {
        self.init(
            standardizedURL:
                url.standardizedFileURL,
            absolutePath: absolutePath,
            relativePath: relativePath,
            depth: depth,
            type: type
        )
    }

    init(
        standardizedURL url: URL,
        absolutePath: StandardPath,
        relativePath: StandardPath,
        depth: Int,
        type: PathSegmentType
    ) {
        self.url = url
        self.absolutePath = absolutePath
        self.relativePath = relativePath
        self.depth = depth
        self.type = type
    }
}
