import Foundation
// backwards compat:

@available(*, message: "use PathSegmentType")
public typealias ProjectPathSegmentType = PathSegmentType

@available(*, message: "use StandardPath")
public typealias ProjectPath = StandardPath

@available(*, deprecated, renamed: "DescendantPath")
public typealias ScopedPath = DescendantPath

public extension AuthorizedPath {
    @available(*, deprecated, renamed: "path")
    var scopedPath: DescendantPath {
        path
    }

    @available(*, deprecated, message: "Create through PathAccessController.authorize(...)")
    init(
        rootIdentifier: PathAccessRootIdentifier,
        scopedPath: DescendantPath,
        absoluteURL: URL,
        presentationPath: String,
        evaluation: PathAccessEvaluation,
        policyChecks: [String]
    ) {
        self.init(
            root: rootIdentifier,
            path: scopedPath,
            url: absoluteURL,
            presentation: presentationPath,
            evaluation: evaluation,
            checks: policyChecks
        )
    }
}

public extension PathAccessController {
    @available(*, deprecated, message: "Use descendants(from:rootIdentifier:)")
    func scopedPaths(
        from result: PathScanResult,
        rootIdentifier: PathAccessRootIdentifier? = nil
    ) throws -> [DescendantPath] {
        try descendants(
            from: result,
            rootIdentifier: rootIdentifier
        )
    }
}

public extension PathAccessScope {
    @available(*, deprecated, message: "Use descendants(from:)")
    func scopedPaths(
        from result: PathScanResult
    ) -> [DescendantPath] {
        descendants(
            from: result
        )
    }

    @available(*, deprecated, message: "Use descendant(from:)")
    func scopedPath(
        from match: PathScanMatch
    ) -> DescendantPath? {
        descendant(
            from: match
        )
    }
}

public extension PathAccessController.ScanAPI {
    @available(*, deprecated, message: "Use descendants(...)")
    func scoped(
        _ specification: PathScanSpecification,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        configuration: PathWalkConfiguration = .init()
    ) throws -> [DescendantPath] {
        try descendants(
            specification,
            rootIdentifier: rootIdentifier,
            configuration: configuration
        )
    }
}
