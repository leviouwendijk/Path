import Foundation
import FileTypes

public enum PathAuthorizationStatus: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case authorized
    case denied
}

public struct PathAuthorizationEntry: Sendable, Codable, Equatable, Hashable, Identifiable {
    public var index: Int
    public var input: String
    public var rootIdentifier: PathAccessRootIdentifier?
    public var status: PathAuthorizationStatus
    public var authorized: AuthorizedPath?
    public var errorDescription: String?

    public init(
        index: Int,
        input: String,
        rootIdentifier: PathAccessRootIdentifier?,
        status: PathAuthorizationStatus,
        authorized: AuthorizedPath? = nil,
        errorDescription: String? = nil
    ) {
        self.index = index
        self.input = input
        self.rootIdentifier = rootIdentifier
        self.status = status
        self.authorized = authorized
        self.errorDescription = errorDescription
    }

    public var id: Int {
        index
    }

    public var isAuthorized: Bool {
        status == .authorized
    }

    public var isDenied: Bool {
        status == .denied
    }
}

public struct PathAuthorizationReport: Sendable, Codable, Equatable, Hashable {
    public var entries: [PathAuthorizationEntry]

    public init(
        entries: [PathAuthorizationEntry]
    ) {
        self.entries = entries
    }

    public var authorized: [AuthorizedPath] {
        entries.compactMap(\.authorized)
    }

    public var denied: [PathAuthorizationEntry] {
        entries.filter(\.isDenied)
    }

    public var authorizedCount: Int {
        authorized.count
    }

    public var deniedCount: Int {
        denied.count
    }

    public var isFullyAuthorized: Bool {
        denied.isEmpty
    }

    public var isEmpty: Bool {
        entries.isEmpty
    }
}

public extension PathAccessController {
    var authorization: AuthorizationAPI {
        .init(
            controller: self
        )
    }

    struct AuthorizationAPI: Sendable, Codable, Hashable {
        public var controller: PathAccessController

        public init(
            controller: PathAccessController
        ) {
            self.controller = controller
        }

        public func report(
            _ scopedPaths: [ScopedPath],
            rootIdentifier: PathAccessRootIdentifier? = nil,
            type: PathSegmentType? = nil
        ) -> PathAuthorizationReport {
            report(
                scopedPaths.enumerated().map { index, path in
                    .init(
                        index: index,
                        input: path.presentingRelative(
                            filetype: true
                        ),
                        authorize: {
                            try controller.authorize(
                                path,
                                rootIdentifier: rootIdentifier,
                                type: type
                            )
                        }
                    )
                },
                rootIdentifier: rootIdentifier
            )
        }

        public func report(
            _ paths: [StandardPath],
            rootIdentifier: PathAccessRootIdentifier? = nil,
            type: PathSegmentType? = nil
        ) -> PathAuthorizationReport {
            report(
                paths.enumerated().map { index, path in
                    .init(
                        index: index,
                        input: path.render(
                            as: .relative,
                            filetype: true
                        ),
                        authorize: {
                            try controller.authorize(
                                path,
                                rootIdentifier: rootIdentifier,
                                type: type
                            )
                        }
                    )
                },
                rootIdentifier: rootIdentifier
            )
        }

        public func report(
            _ urls: [URL],
            rootIdentifier: PathAccessRootIdentifier? = nil,
            type: PathSegmentType? = nil
        ) -> PathAuthorizationReport {
            report(
                urls.enumerated().map { index, url in
                    .init(
                        index: index,
                        input: url.standardizedFileURL.path,
                        authorize: {
                            try controller.authorize(
                                url,
                                rootIdentifier: rootIdentifier,
                                type: type
                            )
                        }
                    )
                },
                rootIdentifier: rootIdentifier
            )
        }

        public func report(
            _ rawPaths: [String],
            rootIdentifier: PathAccessRootIdentifier? = nil,
            filetype: AnyFileType? = nil,
            type: PathSegmentType? = nil
        ) -> PathAuthorizationReport {
            report(
                rawPaths.enumerated().map { index, rawPath in
                    .init(
                        index: index,
                        input: rawPath,
                        authorize: {
                            try controller.authorize(
                                rawPath,
                                rootIdentifier: rootIdentifier,
                                filetype: filetype,
                                type: type
                            )
                        }
                    )
                },
                rootIdentifier: rootIdentifier
            )
        }
    }
}

private extension PathAccessController.AuthorizationAPI {
    struct Attempt {
        var index: Int
        var input: String
        var authorize: () throws -> AuthorizedPath
    }

    func report(
        _ attempts: [Attempt],
        rootIdentifier: PathAccessRootIdentifier?
    ) -> PathAuthorizationReport {
        .init(
            entries: attempts.map { attempt in
                do {
                    let authorized = try attempt.authorize()

                    return .init(
                        index: attempt.index,
                        input: attempt.input,
                        rootIdentifier: authorized.rootIdentifier,
                        status: .authorized,
                        authorized: authorized
                    )
                } catch {
                    return .init(
                        index: attempt.index,
                        input: attempt.input,
                        rootIdentifier: rootIdentifier,
                        status: .denied,
                        errorDescription: errorMessage(
                            error
                        )
                    )
                }
            }
        )
    }

    func errorMessage(
        _ error: Error
    ) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription {
            return description
        }

        return String(
            describing: error
        )
    }
}
