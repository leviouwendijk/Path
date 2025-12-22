import Foundation

extension SegmentConcatenable {
    public var concatenated: String {
        return concatenate(using: "/")
    }

    public func concatenate(using separator: String) -> String {
        return segments.map { $0.value }
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
