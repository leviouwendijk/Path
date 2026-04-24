public extension PathAccessController {
    var scans: ScanAPI {
        .init(
            controller: self
        )
    }

    struct ScanAPI: Sendable, Codable, Hashable {
        public var controller: PathAccessController

        public init(
            controller: PathAccessController
        ) {
            self.controller = controller
        }

        public func matches(
            _ specification: PathScanSpecification,
            rootIdentifier: PathAccessRootIdentifier? = nil,
            configuration: PathWalkConfiguration = .init()
        ) throws -> PathScanResult {
            let root = try controller.root(
                identifier: rootIdentifier
            )
            let result = try PathScan.scan(
                specification,
                relativeTo: .directoryURL(root.rootURL),
                configuration: configuration
            )

            return .init(
                matches: root.scope.filteredMatches(
                    from: result
                ),
                warnings: result.warnings
            )
        }

        public func scoped(
            _ specification: PathScanSpecification,
            rootIdentifier: PathAccessRootIdentifier? = nil,
            configuration: PathWalkConfiguration = .init()
        ) throws -> [ScopedPath] {
            let root = try controller.root(
                identifier: rootIdentifier
            )
            let result = try matches(
                specification,
                rootIdentifier: root.id,
                configuration: configuration
            )

            return root.scope.scopedPaths(
                from: result
            )
        }

        public func authorized(
            _ specification: PathScanSpecification,
            rootIdentifier: PathAccessRootIdentifier? = nil,
            configuration: PathWalkConfiguration = .init()
        ) throws -> AuthorizedPathScanResult {
            let root = try controller.root(
                identifier: rootIdentifier
            )
            let result = try matches(
                specification,
                rootIdentifier: root.id,
                configuration: configuration
            )

            return try .init(
                matches: controller.authorizedPaths(
                    from: result,
                    rootIdentifier: root.id
                ),
                warnings: result.warnings
            )
        }
    }
}
