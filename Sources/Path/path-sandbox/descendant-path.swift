import Foundation

public struct DescendantPath:
    StandardEnvironmentPath,
    Sendable,
    Codable,
    Equatable,
    Hashable
{
    public let root: StandardPath
    public let relative: StandardPath

    public init(
        _ path: StandardPath,
        from root: StandardPath
    ) throws {
        guard root.filetype == nil else {
            throw DescendantPathError.rootMustBeDirectory(
                root
            )
        }

        let root = PathNormalization.root(
            root
        )
        let path = PathNormalization.path(
            path
        )

        guard let relative = PathTree(
            root: root
        ).relative(
            path
        ) else {
            throw DescendantPathError.notDescendant(
                path: path,
                root: root
            )
        }

        self.root = root
        self.relative = relative
    }

    @available(*, deprecated, message: "Use init(_:from:)")
    public init(
        root: StandardPath,
        relative: StandardPath
    ) throws {
        let absolute = try PathTree(
            root: root
        ).appending(
            relative
        )

        try self.init(
            absolute,
            from: root
        )
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

extension DescendantPath {
    private enum CodingKeys: String, CodingKey {
        case root
        case relative
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        let root = try container.decode(
            StandardPath.self,
            forKey: .root
        )
        let relative = try container.decode(
            StandardPath.self,
            forKey: .relative
        )
        let absolute = try PathTree(
            root: root
        ).appending(
            relative
        )

        try self.init(
            absolute,
            from: root
        )
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            root,
            forKey: .root
        )
        try container.encode(
            relative,
            forKey: .relative
        )
    }
}
