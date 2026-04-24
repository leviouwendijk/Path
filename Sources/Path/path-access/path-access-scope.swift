import Foundation
import FileTypes

public struct PathAccessScope: Sendable, Codable, Equatable {
    public let sandbox: PathSandbox
    public let policy: PathAccessPolicy

    public init(
        sandbox: PathSandbox,
        policy: PathAccessPolicy = .defaults.workspace
    ) {
        self.sandbox = sandbox
        self.policy = policy
    }

    public init(
        root: StandardPath,
        policy: PathAccessPolicy = .defaults.workspace
    ) throws {
        self.sandbox = try .init(
            root: root
        )
        self.policy = policy
    }

    public init(
        root: URL,
        policy: PathAccessPolicy = .defaults.workspace
    ) throws {
        try self.init(
            root: StandardPath(
                fileURL: root,
                terminalHint: .directory,
                inferFileType: false
            ),
            policy: policy
        )
    }

    public var root: StandardPath {
        sandbox.root
    }

    public var rootURL: URL {
        URL(
            fileURLWithPath: root.render(
                as: .root,
                filetype: false
            ),
            isDirectory: true
        ).standardizedFileURL
    }
}

public extension PathAccessScope {
    func withPolicy(
        _ policy: PathAccessPolicy
    ) -> Self {
        .init(
            sandbox: sandbox,
            policy: policy
        )
    }

    func applying(
        _ patch: PathAccessPolicyPatch
    ) -> Self {
        withPolicy(
            policy.applying(patch)
        )
    }

    func prepending(
        _ rules: [PathAccessRule]
    ) -> Self {
        withPolicy(
            policy.prepending(rules)
        )
    }

    func appending(
        _ rules: [PathAccessRule]
    ) -> Self {
        withPolicy(
            policy.appending(rules)
        )
    }
}

public extension PathAccessScope {
    func evaluate(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> PathAccessEvaluation {
        policy.evaluate(
            path,
            type: type
        )
    }

    func allows(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        contains(
            path,
            type: type
        )
    }

    func denies(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        !allows(
            path,
            type: type
        )
    }

    func contains(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        (try? require(
            path,
            type: type
        )) != nil
    }

    func contains(
        _ path: StandardPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        (try? resolve(
            path,
            type: type
        )) != nil
    }

    @discardableResult
    func require(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) throws -> ScopedPath {
        guard sandbox.contains(path) else {
            throw PathSandboxError.pathEscapesSandbox(
                path: path.absolute,
                root: root
            )
        }

        let evaluation = policy.evaluate(
            path,
            type: type
        )

        guard evaluation.isAllowed else {
            throw PathAccessError.denied(evaluation)
        }

        return path
    }

    @discardableResult
    func requireAccessible(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) throws -> ScopedPath {
        try require(
            path,
            type: type
        )
    }
}

public extension PathAccessScope {
    func resolve(
        _ path: StandardPath,
        type: PathSegmentType? = nil
    ) throws -> ScopedPath {
        try sandbox.sandbox(
            path,
            policy: policy,
            type: type ?? inferredType(
                for: path
            )
        )
    }

    func resolve(
        rawPath: String,
        filetype: AnyFileType? = nil,
        type: PathSegmentType? = nil
    ) throws -> ScopedPath {
        let scoped = try sandbox.sandbox(
            rawPath: rawPath,
            filetype: filetype
        )

        return try require(
            scoped,
            type: type ?? hintedType(
                rawPath: rawPath,
                filetype: filetype,
                resolved: scoped
            )
        )
    }

    func resolve(
        _ rawPath: String,
        filetype: AnyFileType? = nil,
        type: PathSegmentType? = nil
    ) throws -> ScopedPath {
        try resolve(
            rawPath: rawPath,
            filetype: filetype,
            type: type
        )
    }

    func scope(
        _ url: URL,
        type explicitType: PathSegmentType? = nil
    ) throws -> ScopedPath {
        let existence = PathExistence.check(
            url: url
        )
        let type = explicitType ?? existence.type
        let path = StandardPath(
            fileURL: url,
            terminalHint: terminalHint(
                for: type
            ),
            inferFileType: type == .file
        )

        return try sandbox.sandbox(
            path,
            policy: policy,
            type: type
        )
    }

    func absoluteURL(
        for path: ScopedPath,
        type: PathSegmentType? = nil
    ) throws -> URL {
        let path = try require(
            path,
            type: type
        )

        return absoluteURLUnchecked(
            for: path,
            type: type
        )
    }

    func existingType(
        of path: ScopedPath
    ) throws -> PathSegmentType? {
        let url = try absoluteURL(
            for: path
        )

        return PathExistence.check(
            url: url
        ).type
    }
}

public extension PathAccessScope {
    func filteredMatches(
        from result: PathScanResult
    ) -> [PathScanMatch] {
        result.matches.filter { match in
            guard let scoped = scopedPath(
                from: match
            ) else {
                return false
            }

            return policy.allows(
                scoped,
                type: match.type
            )
        }
    }

    func scopedPaths(
        from result: PathScanResult
    ) -> [ScopedPath] {
        filteredMatches(
            from: result
        ).compactMap {
            scopedPath(
                from: $0
            )
        }
    }

    func scopedPath(
        from match: PathScanMatch
    ) -> ScopedPath? {
        guard let relative = sandbox.tree.relative(
            match.path
        ) else {
            return nil
        }

        guard !relative.segments.isEmpty else {
            return nil
        }

        return ScopedPath(
            root: root,
            relative: relative
        )
    }
}

private extension PathAccessScope {
    func absoluteURLUnchecked(
        for path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> URL {
        URL(
            fileURLWithPath: path.absolute.render(
                as: .root,
                filetype: true
            ),
            isDirectory: type == .directory || (
                type == nil && path.relative.filetype == nil
            )
        ).standardizedFileURL
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
        resolved: ScopedPath
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

    func terminalHint(
        for type: PathSegmentType?
    ) -> PathTerminalHint {
        switch type {
        case .file?:
            return .file

        case .directory?:
            return .directory

        case nil:
            return .unspecified
        }
    }
}
