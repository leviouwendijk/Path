import FileTypes

public struct StandardPathChildAPI: Sendable {
    public let base: StandardPath

    public init(
        base: StandardPath
    ) {
        self.base = base
    }

    public func get(
        _ segments: String...,
        filetype: AnyFileType? = nil
    ) -> StandardPath {
        get(
            segments,
            filetype: filetype
        )
    }

    public func get(
        _ segments: [String],
        filetype: AnyFileType? = nil
    ) -> StandardPath {
        StandardPath(
            from: base,
            segments,
            filetype: filetype
        )
    }

    public func directory(
        _ segments: String...
    ) -> StandardPath {
        directory(
            segments
        )
    }

    public func directory(
        _ segments: [String]
    ) -> StandardPath {
        get(
            segments,
            filetype: nil
        )
    }

    public func file(
        _ segments: String...,
        filetype: AnyFileType? = nil
    ) -> StandardPath {
        file(
            segments,
            filetype: filetype
        )
    }

    public func file(
        _ segments: [String],
        filetype: AnyFileType? = nil
    ) -> StandardPath {
        get(
            segments,
            filetype: filetype
        )
    }
}

public extension StandardPath {
    var child: StandardPathChildAPI {
        StandardPathChildAPI(
            base: self
        )
    }

    func parent() -> StandardPath? {
        guard !segments.isEmpty else {
            return nil
        }

        return StandardPath(
            Array(
                segments.dropLast()
            ),
            filetype: nil
        )
    }
}
