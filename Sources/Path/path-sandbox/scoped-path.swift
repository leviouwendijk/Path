import Foundation

public struct ScopedPath: StandardEnvironmentPath, Sendable, Codable, Equatable {
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
        marker: String = ".",
        separator: String = "/",
        filetype: Bool = true
    ) -> String {
        relative.present(
            .init(
                style: .relative(
                    to: StandardPath.root,
                    marker: marker
                ),
                separator: separator,
                filetype: filetype
            )
        )
    }
}
