import Foundation

public struct AuthorizedPath: Sendable, Codable, Hashable {
    public let rootIdentifier: PathAccessRootIdentifier
    public let path: DescendantPath
    public let absoluteURL: URL
    public let presentationPath: String
    public let evaluation: PathAccessEvaluation
    public let policyChecks: [String]
    /// Where the symlinks the path passes through lead, in order; empty
    /// when it passes through none. Each is in an installed root and passed
    /// that root's policy; a caller that grants per root checks them too.
    public let followed: [Destination]

    /// A followed symlink's destination (with the rest of the path).
    public struct Destination: Sendable, Codable, Hashable {
        public let rootIdentifier: PathAccessRootIdentifier
        public let path: DescendantPath

        public init(
            rootIdentifier: PathAccessRootIdentifier,
            path: DescendantPath
        ) {
            self.rootIdentifier = rootIdentifier
            self.path = path
        }
    }

    private enum CodingKeys: String, CodingKey {
        case rootIdentifier
        case path = "scopedPath"
        case absoluteURL
        case presentationPath
        case evaluation
        case policyChecks
        case followed
    }

    init(
        root: PathAccessRootIdentifier,
        path: DescendantPath,
        url: URL,
        presentation: String,
        evaluation: PathAccessEvaluation,
        checks: [String],
        followed: [Destination] = []
    ) {
        self.rootIdentifier = root
        self.path = path
        self.absoluteURL = url
        self.presentationPath = presentation
        self.evaluation = evaluation
        self.policyChecks = checks
        self.followed = followed
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rootIdentifier = try container.decode(PathAccessRootIdentifier.self, forKey: .rootIdentifier)
        self.path = try container.decode(DescendantPath.self, forKey: .path)
        self.absoluteURL = try container.decode(URL.self, forKey: .absoluteURL)
        self.presentationPath = try container.decode(String.self, forKey: .presentationPath)
        self.evaluation = try container.decode(PathAccessEvaluation.self, forKey: .evaluation)
        self.policyChecks = try container.decode([String].self, forKey: .policyChecks)
        self.followed = try container.decodeIfPresent([Destination].self, forKey: .followed) ?? []
    }
}

public extension AuthorizedPath {
    /// The same authorization, shown as `presentation`.
    func presenting(
        _ presentation: String
    ) -> AuthorizedPath {
        .init(
            root: rootIdentifier,
            path: path,
            url: absoluteURL,
            presentation: presentation,
            evaluation: evaluation,
            checks: policyChecks,
            followed: followed
        )
    }

    var qualifiedPresentationPath: String {
        presentingQualified()
    }

    func presentingQualified(
        separator: String = ":"
    ) -> String {
        "\(rootIdentifier.rawValue)\(separator)\(presentationPath)"
    }
}
