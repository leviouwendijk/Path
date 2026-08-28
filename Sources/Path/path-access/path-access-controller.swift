import Foundation
import FileTypes

public struct PathAccessController: Sendable, Codable, Hashable {
    public var roots: [PathAccessRootIdentifier: PathAccessRoot]
    public var defaultRootIdentifier: PathAccessRootIdentifier?

    public init(
        roots: [PathAccessRoot] = [],
        defaultRootIdentifier: PathAccessRootIdentifier? = nil
    ) {
        var mappedRoots: [PathAccessRootIdentifier: PathAccessRoot] = [:]

        for root in roots {
            mappedRoots[root.id] = root
        }

        var resolvedDefaultIdentifier = defaultRootIdentifier.flatMap {
            mappedRoots[$0] == nil ? nil : $0
        }

        if resolvedDefaultIdentifier == nil {
            resolvedDefaultIdentifier = mappedRoots.values.first {
                $0.isDefault
            }?.id
        }

        if resolvedDefaultIdentifier == nil {
            resolvedDefaultIdentifier = mappedRoots.keys.sorted {
                $0.rawValue < $1.rawValue
            }.first
        }

        if let resolvedDefaultIdentifier {
            for rootIdentifier in Array(mappedRoots.keys) {
                mappedRoots[rootIdentifier]?.isDefault = rootIdentifier == resolvedDefaultIdentifier
            }
        }

        self.roots = mappedRoots
        self.defaultRootIdentifier = resolvedDefaultIdentifier
    }

    public init(
        roots: [PathAccessRootIdentifier: PathAccessRoot],
        defaultRootIdentifier: PathAccessRootIdentifier? = nil
    ) {
        self.init(
            roots: Array(roots.values),
            defaultRootIdentifier: defaultRootIdentifier
        )
    }
}

public extension PathAccessController {
    static func project(
        scope: PathAccessScope,
        identifier: PathAccessRootIdentifier = .project,
        label: String = "Project",
        details: String? = nil
    ) -> Self {
        .init(
            roots: [
                .init(
                    id: identifier,
                    label: label,
                    scope: scope,
                    details: details,
                    isDefault: true
                )
            ],
            defaultRootIdentifier: identifier
        )
    }

    var rootIdentifiers: [PathAccessRootIdentifier] {
        roots.keys.sorted {
            $0.rawValue < $1.rawValue
        }
    }

    func resolvedRootIdentifier(
        _ rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> PathAccessRootIdentifier {
        if let rootIdentifier {
            return rootIdentifier
        }

        if let defaultRootIdentifier {
            return defaultRootIdentifier
        }

        if let first = rootIdentifiers.first {
            return first
        }

        throw PathAccessControllerError.defaultRootUnavailable
    }

    func root(
        identifier rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> PathAccessRoot {
        let rootIdentifier = try resolvedRootIdentifier(
            rootIdentifier
        )

        guard let root = roots[rootIdentifier] else {
            throw PathAccessControllerError.rootNotFound(
                rootIdentifier
            )
        }

        return root
    }
}

public extension PathAccessController {
    func installing(
        _ root: PathAccessRoot
    ) -> Self {
        var copy = self
        var root = root

        if root.isDefault || copy.roots.isEmpty {
            copy.defaultRootIdentifier = root.id
            root.isDefault = true
        }

        copy.roots[root.id] = root

        return copy.normalized()
    }

    func installing(
        rootIdentifier: PathAccessRootIdentifier,
        label: String,
        scope: PathAccessScope,
        details: String? = nil,
        isDefault: Bool = false
    ) -> Self {
        installing(
            .init(
                id: rootIdentifier,
                label: label,
                scope: scope,
                details: details,
                isDefault: isDefault
            )
        )
    }

    func removingRoot(
        identifier rootIdentifier: PathAccessRootIdentifier
    ) -> Self {
        var copy = self

        copy.roots.removeValue(
            forKey: rootIdentifier
        )

        if copy.defaultRootIdentifier == rootIdentifier {
            copy.defaultRootIdentifier = nil
        }

        return copy.normalized()
    }

    func replacingRootScope(
        rootIdentifier: PathAccessRootIdentifier,
        scope: PathAccessScope
    ) -> Self {
        var copy = self

        if let existing = copy.roots[rootIdentifier] {
            copy.roots[rootIdentifier] = existing.withScope(
                scope
            )

            return copy.normalized()
        }

        return copy.installing(
            rootIdentifier: rootIdentifier,
            label: rootIdentifier == .project ? "Project" : rootIdentifier.rawValue,
            scope: scope,
            isDefault: copy.roots.isEmpty || rootIdentifier == .project
        )
    }

    func withPolicy(
        _ policy: PathAccessPolicy,
        rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> Self {
        let rootIdentifier = try resolvedRootIdentifier(
            rootIdentifier
        )
        let root = try root(
            identifier: rootIdentifier
        )

        var copy = self
        copy.roots[rootIdentifier] = root.withPolicy(
            policy
        )

        return copy.normalized()
    }

    func applying(
        _ patch: PathAccessPolicyPatch,
        rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> Self {
        let rootIdentifier = try resolvedRootIdentifier(
            rootIdentifier
        )
        let root = try root(
            identifier: rootIdentifier
        )

        var copy = self
        copy.roots[rootIdentifier] = root.applying(
            patch
        )

        return copy.normalized()
    }
}

public extension PathAccessController {
    func evaluate(
        _ descendant: DescendantPath,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> PathAccessEvaluation {
        let root = try root(
            identifier: rootIdentifier
        )

        guard root.scope.sandbox.contains(descendant) else {
            throw PathAccessControllerError.rootMismatch(
                rootIdentifier: root.id,
                expectedRoot: root.scope.root,
                actualRoot: descendant.root
            )
        }

        return root.scope.evaluate(
            descendant,
            type: type
        )
    }

    func evaluate(
        _ path: StandardPath,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> PathAccessEvaluation {
        let root = try root(
            identifier: rootIdentifier
        )
        let descendant = try root.scope.sandbox.sandbox(
            path
        )

        return root.scope.evaluate(
            descendant,
            type: type ?? inferredType(
                for: path
            )
        )
    }

    func evaluate(
        _ rawPath: String,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        filetype: AnyFileType? = nil,
        type: PathSegmentType? = nil
    ) throws -> PathAccessEvaluation {
        let root = try root(
            identifier: rootIdentifier
        )
        let descendant = try root.scope.sandbox.sandbox(
            rawPath: rawPath,
            filetype: filetype
        )

        return root.scope.evaluate(
            descendant,
            type: type ?? hintedType(
                rawPath: rawPath,
                filetype: filetype,
                resolved: descendant
            )
        )
    }

    @discardableResult
    func require(
        _ descendant: DescendantPath,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> DescendantPath {
        let root = try root(
            identifier: rootIdentifier
        )

        return try root.scope.requireAccessible(
            descendant,
            type: type
        )
    }

    func contains(
        _ descendant: DescendantPath,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) -> Bool {
        (try? require(
            descendant,
            rootIdentifier: rootIdentifier,
            type: type
        )) != nil
    }
}

public extension PathAccessController {
    func resolve(
        _ path: StandardPath,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> DescendantPath {
        let root = try root(
            identifier: rootIdentifier
        )

        return try root.scope.resolve(
            path,
            type: type
        )
    }

    func resolve(
        _ rawPath: String,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        filetype: AnyFileType? = nil,
        type: PathSegmentType? = nil
    ) throws -> DescendantPath {
        let root = try root(
            identifier: rootIdentifier
        )

        return try root.scope.resolve(
            rawPath: rawPath,
            filetype: filetype,
            type: type
        )
    }

    func scope(
        _ url: URL,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> DescendantPath {
        let root = try root(
            identifier: rootIdentifier
        )

        return try root.scope.scope(
            url,
            type: type
        )
    }

    func absoluteURL(
        for descendant: DescendantPath,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> URL {
        let root = try root(
            identifier: rootIdentifier
        )

        return try root.scope.absoluteURL(
            for: descendant,
            type: type
        )
    }

    func existingType(
        of descendant: DescendantPath,
        rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> PathSegmentType? {
        let root = try root(
            identifier: rootIdentifier
        )

        return try root.scope.existingType(
            of: descendant
        )
    }
}

public extension PathAccessController {
    func authorize(
        _ descendant: DescendantPath,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> AuthorizedPath {
        let root = try root(
            identifier: rootIdentifier
        )
        let accessible = try root.scope.requireAccessible(
            descendant,
            type: type
        )
        let evaluation = root.scope.evaluate(
            accessible,
            type: type
        )
        let absoluteURL = try root.scope.absoluteURL(
            for: accessible,
            type: type
        )

        return .init(
            root: root.id,
            path: accessible,
            url: absoluteURL,
            presentation: accessible.presentingRelative(
                filetype: true
            ),
            evaluation: evaluation,
            checks: [
                "root_resolved",
                "path_sandboxed",
                "path_policy_allowed"
            ]
        )
    }

    func authorize(
        _ path: StandardPath,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        type: PathSegmentType? = nil
    ) throws -> AuthorizedPath {
        let root = try root(
            identifier: rootIdentifier
        )
        let descendant = try root.scope.resolve(
            path,
            type: type
        )

        return try authorize(
            descendant,
            rootIdentifier: root.id,
            type: type
        )
    }

    func authorize(
        _ rawPath: String,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        filetype: AnyFileType? = nil,
        type: PathSegmentType? = nil
    ) throws -> AuthorizedPath {
        let root = try root(
            identifier: rootIdentifier
        )
        let descendant = try root.scope.resolve(
            rawPath: rawPath,
            filetype: filetype,
            type: type
        )

        return try authorize(
            descendant,
            rootIdentifier: root.id,
            type: type
        )
    }
}

public extension PathAccessController {
    func filteredMatches(
        from result: PathScanResult,
        rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> [PathScanMatch] {
        let root = try root(
            identifier: rootIdentifier
        )

        return root.scope.filteredMatches(
            from: result
        )
    }

    func descendants(
        from result: PathScanResult,
        rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> [DescendantPath] {
        let root = try root(
            identifier: rootIdentifier
        )

        return root.scope.descendants(
            from: result
        )
    }

    func authorizedPaths(
        from result: PathScanResult,
        rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> [AuthorizedPath] {
        let root = try root(
            identifier: rootIdentifier
        )
        let matches = root.scope.filteredMatches(
            from: result
        )

        return try matches.compactMap { match in
            guard let descendant = root.scope.descendant(
                from: match
            ) else {
                return nil
            }

            return try authorize(
                descendant,
                rootIdentifier: root.id,
                type: match.type
            )
        }
    }
}

public extension PathAccessController {
    func exposureReport(
        rootIdentifier: PathAccessRootIdentifier? = nil,
        proposedPolicy: PathAccessPolicy = .allowAll,
        sensitivity: PathSensitivityProfile = .agenticConservative,
        configuration: PathExposureScanConfiguration = .default
    ) throws -> PathExposureReport {
        let root = try root(
            identifier: rootIdentifier
        )

        return try PathExposureScan.scan(
            .init(
                root: root.scope.root,
                baselinePolicy: root.scope.policy,
                proposedPolicy: proposedPolicy,
                sensitivity: sensitivity,
                configuration: configuration
            )
        )
    }

    func exposureReport(
        rootIdentifier: PathAccessRootIdentifier? = nil,
        applying patch: PathAccessPolicyPatch,
        sensitivity: PathSensitivityProfile = .agenticConservative,
        configuration: PathExposureScanConfiguration = .default
    ) throws -> PathExposureReport {
        let root = try root(
            identifier: rootIdentifier
        )

        return try exposureReport(
            rootIdentifier: root.id,
            proposedPolicy: root.scope.policy.applying(
                patch
            ),
            sensitivity: sensitivity,
            configuration: configuration
        )
    }
}

private extension PathAccessController {
    func normalized() -> Self {
        .init(
            roots: Array(roots.values),
            defaultRootIdentifier: defaultRootIdentifier
        )
    }

    func inferredType(
        for path: StandardPath
    ) -> PathSegmentType? {
        if path.filetype != nil {
            return .file
        }

        return nil
    }

    func hintedType(
        rawPath: String,
        filetype: AnyFileType?,
        resolved: DescendantPath
    ) -> PathSegmentType? {
        if filetype != nil {
            return .file
        }

        let trimmed = rawPath.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmed.hasSuffix("/") {
            return .directory
        }

        if resolved.relative.filetype != nil {
            return .file
        }

        return nil
    }
}
