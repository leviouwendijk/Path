import Foundation

extension SegmentConcatenable {
    public func concatenate(
        using separator: String,
        includeFileType: Bool = true
    ) -> String {
        var comps = segments.map { $0.value }

        if includeFileType {
            if let filetype {
                comps.append(filetype.component)
            }
        }

        return comps
        .joined(separator: separator)
    }

    public func url(base: URL) -> URL {
        var res = base
        for i in segments {
            res = res.appendingPathComponent(i.value)
        }
        return res
    }

    public func rendered(
        using separator: String = "/",
        asRootPath: Bool,
        includeFileType: Bool = true
    ) -> String {
        // let concat = self.concatenated
        let concat = concatenate(using: separator, includeFileType: includeFileType)
        let prefixed = asRootPath ? "/" + concat : concat
        return prefixed.removed_double_slashes
    }
}

// convenience concatenate access
extension SegmentConcatenable {
    @available(*, message: "use func () instead")
    public var concatenated: String {
        return concatenate(using: "/")
    }

    public func concatenated(
        using separator: String = "/",
        includeFileType: Bool = true
    ) -> String {
        concatenate(using: separator, includeFileType: includeFileType)
    }
}
