public struct WebReference: Sendable, Equatable, CustomStringConvertible {
    public var origin: String?
    public var path: StandardPath
    public var query: [WebQueryItem]
    public var fragment: String?

    public init(
        origin: String? = nil,
        path: StandardPath = StandardPath(),
        query: [WebQueryItem] = [],
        fragment: String? = nil
    ) {
        self.origin = origin
        self.path = path
        self.query = query
        self.fragment = fragment
    }

    public func rendered(asRootPath: Bool = true) -> String {
        var result = ""

        if let origin {
            result += origin
        }

        let pathStr = path.rendered(asRootPath: origin == nil && asRootPath)
        if pathStr == "/" && origin != nil {
            result += "/"
        } else if !pathStr.isEmpty && pathStr != "/" {
            result += pathStr
        }

        if !query.isEmpty {
            result += "?"
            result += query
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
        }

        if let fragment {
            result += "#\(fragment)"
        }

        return result
    }

    public var description: String {
        rendered()
    }
}

extension WebReference {
    public static func rootRelative(
        _ path: StandardPath,
        query: [WebQueryItem] = []
    ) -> WebReference {
        WebReference(path: path, query: query)
    }

    public static func versioned(
        _ path: StandardPath,
        version: String
    ) -> WebReference {
        WebReference(path: path, query: [.init(key: "v", value: version)])
    }

    public static func absolute(
        origin: String,
        path: StandardPath = StandardPath(),
        query: [WebQueryItem] = []
    ) -> WebReference {
        WebReference(origin: origin, path: path, query: query)
    }

    public static func fragment(_ id: String) -> WebReference {
        WebReference(fragment: id)
    }
}
