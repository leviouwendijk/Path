public struct PathAccessRootIdentifier: Sendable, Codable, Hashable, RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: StringLiteralType
    ) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }
}

public extension PathAccessRootIdentifier {
    static let project: Self = "project"
}
