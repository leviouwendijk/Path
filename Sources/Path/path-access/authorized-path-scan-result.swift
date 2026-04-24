public struct AuthorizedPathScanResult: Sendable, Codable, Equatable {
    public var matches: [AuthorizedPath]
    public var warnings: [PathScanWarning]

    public init(
        matches: [AuthorizedPath],
        warnings: [PathScanWarning] = []
    ) {
        self.matches = matches
        self.warnings = warnings
    }

    public var isEmpty: Bool {
        matches.isEmpty
    }
}
