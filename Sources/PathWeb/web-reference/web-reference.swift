import Foundation
import Path
import Methods
import ProtocolComponents

public struct WebReference: Sendable, Codable, Equatable, CustomStringConvertible {
    public var origin: WebOrigin?
    public var path: StandardPath?
    public var query: [WebQueryItem]
    public var fragment: String?

    private init(
        uncheckedOrigin origin: WebOrigin? = nil,
        path: StandardPath? = nil,
        query: [WebQueryItem] = [],
        fragment: String? = nil
    ) {
        self.origin = origin
        self.path = path
        self.query = WebQueryItem.normalized(query)
        self.fragment = fragment.trimmedOrNil
    }

    public init(
        origin: WebOrigin? = nil,
        path: StandardPath? = nil,
        query: [WebQueryItem] = [],
        fragment: String? = nil,
        constraints: WebReferenceConstraints = WebReferenceConstraintSets.standard
    ) throws {
        let query = WebQueryItem.normalized(query)
        let fragment = fragment.trimmedOrNil

        let violations = Self.violations(
            origin: origin,
            path: path,
            query: query,
            fragment: fragment,
            constraints: constraints
        )

        guard violations.isEmpty else {
            throw WebReferenceConstraintViolationError(
                violations: violations
            )
        }

        self.init(
            uncheckedOrigin: origin,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    public static func parse(
        origin: WebOrigin? = nil,
        path: StandardPath? = nil,
        query: [WebQueryItem] = [],
        fragment: String? = nil,
        constraints: WebReferenceConstraints = WebReferenceConstraintSets.standard
    ) throws -> WebReference {
        try WebReference(
            origin: origin,
            path: path,
            query: query,
            fragment: fragment,
            constraints: constraints
        )
    }

    public static func violations(
        origin: WebOrigin? = nil,
        path: StandardPath? = nil,
        query: [WebQueryItem] = [],
        fragment: String? = nil,
        constraints: WebReferenceConstraints = WebReferenceConstraintSets.standard
    ) -> [WebReferenceConstraintViolation] {
        let query = WebQueryItem.normalized(query)
        let fragment = fragment.trimmedOrNil

        var violations: [WebReferenceConstraintViolation] = []

        let hasOrigin = origin != nil
        let hasPath = path != nil
        let hasQuery = !query.isEmpty
        let hasFragment = fragment != nil

        let hasBase = hasOrigin || hasPath
        let hasTarget = hasBase || hasFragment

        if constraints.contains(.requiresTarget) && !hasTarget {
            violations.append(
                .init(
                    constraint: .requiresTarget,
                    origin: origin?.description,
                    path: path,
                    query: query,
                    fragment: fragment
                )
            )
        }

        if constraints.contains(.requiresBaseForQuery) && hasQuery && !hasBase {
            violations.append(
                .init(
                    constraint: .requiresBaseForQuery,
                    origin: origin?.description,
                    path: path,
                    query: query,
                    fragment: fragment
                )
            )
        }

        return violations
    }

    public func violations(
        constraints: WebReferenceConstraints = WebReferenceConstraintSets.standard
    ) -> [WebReferenceConstraintViolation] {
        Self.violations(
            origin: origin,
            path: path,
            query: query,
            fragment: fragment,
            constraints: constraints
        )
    }

    public var hasBase: Bool {
        return origin != nil || path != nil
    }

    public var hasTarget: Bool {
        return hasBase || fragment.trimmedOrNil != nil
    }

    public var isAbsolute: Bool {
        return origin != nil
    }

    public var isFragmentOnly: Bool {
        return origin == nil &&
            path == nil &&
            WebQueryItem.normalized(query).isEmpty &&
            fragment.trimmedOrNil != nil
    }

    public func render(
        as relativity: PathRelativity = .root
    ) -> String {
        let query = WebQueryItem.normalized(query)
        let fragment = fragment.trimmedOrNil

        var result = ""

        if let origin {
            result += origin.description
        }

        if let path {
            let renderedPath = path.render(
                as: origin == nil ? relativity : .relative
            )

            if origin == nil {
                result += renderedPath
            } else if renderedPath.isEmpty {
                result += "/"
            } else {
                result += "/\(renderedPath)"
            }
        }

        if let encodedQuery = WebReferenceEncoding.query(query) {
            result += "?\(encodedQuery)"
        }

        if let encodedFragment = WebReferenceEncoding.fragment(fragment) {
            result += "#\(encodedFragment)"
        }

        return result
    }

    public var description: String {
        render()
    }
}

extension WebReference {
    public static func unchecked(
        origin: WebOrigin? = nil,
        path: StandardPath? = nil,
        query: [WebQueryItem] = [],
        fragment: String? = nil
    ) -> WebReference {
        WebReference(
            uncheckedOrigin: origin,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    public static func local(
        _ path: StandardPath,
        query: [WebQueryItem] = [],
        fragment: String? = nil
    ) -> WebReference {
        .unchecked(
            path: path,
            query: query,
            fragment: fragment
        )
    }

    public static func absolute(
        origin: WebOrigin,
        path: StandardPath = StandardPath(),
        query: [WebQueryItem] = [],
        fragment: String? = nil
    ) -> WebReference {
        .unchecked(
            origin: origin,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    public static func fragment(
        _ id: String
    ) -> WebReference {
        .unchecked(fragment: id)
    }

    public static func versioned(
        _ path: StandardPath,
        version: String,
        fragment: String? = nil
    ) -> WebReference {
        .unchecked(
            path: path,
            query: [.init(key: "v", value: version)],
            fragment: fragment
        )
    }
}

extension WebReference {
    public func withOrigin(
        _ origin: WebOrigin?
    ) -> WebReference {
        .unchecked(
            origin: origin,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    public func withPath(
        _ path: StandardPath?
    ) -> WebReference {
        .unchecked(
            origin: origin,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    public func withFragment(
        _ fragment: String?
    ) -> WebReference {
        .unchecked(
            origin: origin,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    public func withoutFragment() -> WebReference {
        withFragment(nil)
    }

    public func withQuery(
        _ query: [WebQueryItem]
    ) -> WebReference {
        .unchecked(
            origin: origin,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    public func clearingQuery() -> WebReference {
        withQuery([])
    }

    public func appending(
        query item: WebQueryItem
    ) -> WebReference {
        appending(query: [item])
    }

    public func appending(
        query items: [WebQueryItem]
    ) -> WebReference {
        .unchecked(
            origin: origin,
            path: path,
            query: query + items,
            fragment: fragment
        )
    }

    public func removingQuery(
        named key: String
    ) -> WebReference {
        .unchecked(
            origin: origin,
            path: path,
            query: query.filter { $0.key != key },
            fragment: fragment
        )
    }

    public func merging(
        query items: [WebQueryItem]
    ) -> WebReference {
        var merged = WebQueryItem.normalized(query)

        for item in WebQueryItem.normalized(items) {
            if let index = merged.lastIndex(where: { $0.key == item.key }) {
                merged[index] = item
            } else {
                merged.append(item)
            }
        }

        return .unchecked(
            origin: origin,
            path: path,
            query: merged,
            fragment: fragment
        )
    }

    public func versioning(
        _ version: String
    ) -> WebReference {
        removingQuery(named: "v")
            .appending(query: .init(key: "v", value: version))
    }
}
