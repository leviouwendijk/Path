import Foundation

public struct AuthorizedPath: Sendable, Codable, Hashable {
    public let rootIdentifier: PathAccessRootIdentifier
    public let path: DescendantPath
    public let absoluteURL: URL
    public let presentationPath: String
    public let evaluation: PathAccessEvaluation
    public let policyChecks: [String]

    private enum CodingKeys: String, CodingKey {
        case rootIdentifier
        case path = "scopedPath"
        case absoluteURL
        case presentationPath
        case evaluation
        case policyChecks
    }

    init(
        root: PathAccessRootIdentifier,
        path: DescendantPath,
        url: URL,
        presentation: String,
        evaluation: PathAccessEvaluation,
        checks: [String]
    ) {
        self.rootIdentifier = root
        self.path = path
        self.absoluteURL = url
        self.presentationPath = presentation
        self.evaluation = evaluation
        self.policyChecks = checks
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
