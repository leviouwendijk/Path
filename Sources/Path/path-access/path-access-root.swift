import Foundation

public struct PathAccessRoot: Sendable, Codable, Hashable, Identifiable {
    public let id: PathAccessRootIdentifier
    public var label: String
    public var scope: PathAccessScope
    public var details: String?
    public var isDefault: Bool

    public init(
        id: PathAccessRootIdentifier,
        label: String,
        scope: PathAccessScope,
        details: String? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.label = label
        self.scope = scope
        self.details = details
        self.isDefault = isDefault
    }
}

public extension PathAccessRoot {
    var root: StandardPath {
        scope.root
    }

    var rootURL: URL {
        scope.rootURL
    }

    var rootPath: String {
        rootURL.path
    }

    func withScope(
        _ scope: PathAccessScope
    ) -> Self {
        .init(
            id: id,
            label: label,
            scope: scope,
            details: details,
            isDefault: isDefault
        )
    }

    func withPolicy(
        _ policy: PathAccessPolicy
    ) -> Self {
        withScope(
            scope.withPolicy(policy)
        )
    }

    func applying(
        _ patch: PathAccessPolicyPatch
    ) -> Self {
        withScope(
            scope.applying(patch)
        )
    }
}
