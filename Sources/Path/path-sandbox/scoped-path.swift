import Foundation

public struct ScopedPath: StandardEnvironmentPath, Sendable, Codable, Equatable, Hashable {
    public let root: StandardPath
    public let relative: StandardPath

    public init(
        root: StandardPath,
        relative: StandardPath
    ) {
        self.root = root
        self.relative = relative
    }

    public var standard_path: StandardPath {
        StandardPath(
            from: root,
            relative.segments.map(\.value),
            filetype: relative.filetype
        )
    }

    public var absolute: StandardPath {
        standard_path
    }

    public func presentingRelative(
        separator: String = "/",
        filetype: Bool = true
    ) -> String {
        relative.render(
            as: .relative,
            separator: separator,
            filetype: filetype
        )
    }
}
