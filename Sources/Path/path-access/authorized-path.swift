import Foundation

public struct AuthorizedPath: Sendable, Codable, Hashable {
    public let rootIdentifier: PathAccessRootIdentifier
    public let scopedPath: ScopedPath
    public let absoluteURL: URL
    public let presentationPath: String
    public let evaluation: PathAccessEvaluation
    public let policyChecks: [String]

    public init(
        rootIdentifier: PathAccessRootIdentifier,
        scopedPath: ScopedPath,
        absoluteURL: URL,
        presentationPath: String,
        evaluation: PathAccessEvaluation,
        policyChecks: [String]
    ) {
        self.rootIdentifier = rootIdentifier
        self.scopedPath = scopedPath
        self.absoluteURL = absoluteURL
        self.presentationPath = presentationPath
        self.evaluation = evaluation
        self.policyChecks = policyChecks
    }
}

public extension AuthorizedPath {
    var qualifiedPresentationPath: String {
        presentingQualified()
    }

    func presentingQualified(
        separator: String = ":"
    ) -> String {
        "\(rootIdentifier.rawValue)\(separator)\(presentationPath)"
    }
}
