import Foundation

extension SegmentConcatenable {
    public var concatenated: String {
        return concatenate(using: "/")
    }

    public func concatenate(using separator: String) -> String {
        var comps = segments.map { $0.value }
        if let filetype {
            comps.append(filetype.component)
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

    public func rendered(asRootPath: Bool) -> String {
        let concat = self.concatenated
        let prefixed = asRootPath ? "/" + concat : concat
        return prefixed.removed_double_slashes
    }
}
