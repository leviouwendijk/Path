public extension PathAccessController {
    var defaultRoot: DefaultRootAPI {
        .init(
            controller: self
        )
    }

    func withDefaultRoot(
        _ rootIdentifier: PathAccessRootIdentifier
    ) throws -> Self {
        guard roots[rootIdentifier] != nil else {
            throw PathAccessControllerError.rootNotFound(
                rootIdentifier
            )
        }

        var copy = self
        copy.defaultRootIdentifier = rootIdentifier

        for key in Array(copy.roots.keys) {
            copy.roots[key]?.isDefault = key == rootIdentifier
        }

        return copy
    }

    struct DefaultRootAPI: Sendable, Codable, Hashable {
        public var controller: PathAccessController

        public init(
            controller: PathAccessController
        ) {
            self.controller = controller
        }

        public var identifier: PathAccessRootIdentifier? {
            controller.defaultRootIdentifier
        }

        public func resolvedIdentifier() throws -> PathAccessRootIdentifier {
            try controller.resolvedRootIdentifier()
        }

        public func root() throws -> PathAccessRoot {
            try controller.root()
        }

        public func setting(
            _ rootIdentifier: PathAccessRootIdentifier
        ) throws -> PathAccessController {
            try controller.withDefaultRoot(
                rootIdentifier
            )
        }
    }
}
