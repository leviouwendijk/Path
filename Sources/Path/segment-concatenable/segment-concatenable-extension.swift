import Foundation

extension SegmentConcatenable {
    @available(*, message: "Use filetype instead of includeFileType")
    public func concatenate(
        using separator: String,
        includeFileType: Bool = true
    ) -> String {
        return concatenate(
            using: separator,
            filetype: includeFileType
        )
    }

    public func concatenate(
        using separator: String,
        filetype includeFileType: Bool = true
    ) -> String {
        var res: String = ""

        let comps = segments.map { $0.value }
        let joined = comps
        .joined(separator: separator)

        res.append(joined)

        if includeFileType {
            if let filetype {
                res.append(filetype.component)
            }
        }

        return res
    }

    public func url(
        base: URL,
        includeFileType: Bool = true
    ) -> URL {
        guard !segments.isEmpty else { return base }

        var res = base

        let seg_n = segments.count
        let last_seg_idx = seg_n - 1

        for (idx, segment) in segments.enumerated() {
            if (idx == last_seg_idx) && (includeFileType), let filetype {
                let filetyped_segment = segment + filetype

                res = res.appendingPathComponent(
                    filetyped_segment.value
                )
            } else {
                res = res.appendingPathComponent(segment.value)
            }
        }
        return res
    }

    public func root_url(
        includeFileType: Bool = true
    ) -> URL {
        let root = URL(fileURLWithPath: "/", isDirectory: true)
        return url(base: root, includeFileType: includeFileType)
    }

    @available(*, message: "superseded by path(as:, separator: , filetype:)")
    public func rendered(
        using separator: String = "/",
        asRootPath: Bool,
        includeFileType: Bool = true
    ) -> String {
        // let concat = self.concatenated
        let concat = concatenate(
            using: separator,
            filetype: includeFileType
        )
        let prefixed = asRootPath ? "/" + concat : concat
        return prefixed.removed_double_slashes
    }
}

extension SegmentConcatenable {
    public func path(
        as relativity: PathRelativity,
        separator: String = "/",
        filetype: Bool = true
    ) -> String {
        let concat = concatenate(
            using: separator,
            filetype: filetype
        )
        var path: String = ""
        if let prefix = relativity.prefix {
            path += prefix
        }
        path += concat

        return path.removed_double_slashes
    }
}

// convenience concatenate access
extension SegmentConcatenable {
    @available(*, message: "use func () instead")
    public var concatenated: String {
        return concatenate(using: "/", filetype: true)
    }

    public func concatenated(
        using separator: String = "/",
        includeFileType: Bool = true
    ) -> String {
        concatenate(using: separator, includeFileType: includeFileType)
    }
}
