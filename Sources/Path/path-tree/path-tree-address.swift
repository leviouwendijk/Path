import FileTypes

public struct PathTreeAddress<Kind: PathTreeNodeKind>: Sendable, Codable, Equatable, Hashable, ExpressibleByStringLiteral {
    public var path: StandardPath

    public init(
        _ path: StandardPath
    ) {
        self.path = PathNormalization.path(path)
    }

    public init(
        rawPath: String,
        filetype: AnyFileType? = nil
    ) {
        self.init(
            StandardPath(
                rawPath: rawPath,
                filetype: filetype
            )
        )
    }

    public init(
        _ rawPath: String,
        filetype: AnyFileType? = nil
    ) {
        self.init(
            rawPath: rawPath,
            filetype: filetype
        )
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(rawPath: value)
    }
}

public extension PathTreeAddress {
    var renderedPath: String {
        path.render(
            as: .relative,
            filetype: true
        )
    }

    var parent: PathTreeDirectoryAddress? {
        guard !path.segments.isEmpty else {
            return nil
        }

        return PathTreeDirectoryAddress(
            StandardPath(
                Array(path.segments.dropLast())
            )
        )
    }

    func erased() -> PathTreeAnyNodeAddress {
        PathTreeAnyNodeAddress(path)
    }
}

public extension PathTreeAddress where Kind == PathTreeDirectoryKind {
    static var root: Self {
        Self(StandardPath())
    }

    func directory(
        _ component: String
    ) -> PathTreeDirectoryAddress {
        PathTreeDirectoryAddress(
            appending(
                StandardPath(
                    segments: [
                        PathSegment(
                            component,
                            .directory
                        )
                    ]
                )
            )
        )
    }

    func directoryPath(
        _ rawPath: String
    ) -> PathTreeDirectoryAddress {
        PathTreeDirectoryAddress(
            appending(
                StandardPath(rawPath: rawPath)
            )
        )
    }

    func file(
        _ component: String,
        filetype: AnyFileType? = nil
    ) -> PathTreeFileAddress {
        PathTreeFileAddress(
            appending(
                StandardPath(
                    segments: [
                        PathSegment(
                            component,
                            .file
                        )
                    ],
                    filetype: filetype
                )
            )
        )
    }

    func filePath(
        _ rawPath: String,
        filetype: AnyFileType? = nil
    ) -> PathTreeFileAddress {
        PathTreeFileAddress(
            appending(
                StandardPath(
                    rawPath: rawPath,
                    filetype: filetype
                )
            )
        )
    }

    func node(
        _ component: String,
        type: PathSegmentType? = nil,
        filetype: AnyFileType? = nil
    ) -> PathTreeAnyNodeAddress {
        PathTreeAnyNodeAddress(
            appending(
                StandardPath(
                    segments: [
                        PathSegment(
                            component,
                            type
                        )
                    ],
                    filetype: filetype
                )
            )
        )
    }

    func nodePath(
        _ rawPath: String,
        filetype: AnyFileType? = nil
    ) -> PathTreeAnyNodeAddress {
        PathTreeAnyNodeAddress(
            appending(
                StandardPath(
                    rawPath: rawPath,
                    filetype: filetype
                )
            )
        )
    }
}

private extension PathTreeAddress where Kind == PathTreeDirectoryKind {
    func appending(
        _ relative: StandardPath
    ) -> StandardPath {
        StandardPath(
            segments: path.segments + relative.segments,
            filetype: relative.filetype
        )
    }
}
