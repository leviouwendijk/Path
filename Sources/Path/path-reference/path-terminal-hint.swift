public enum PathTerminalHint: String, Sendable, Codable, Equatable {
    case file
    case directory
    case unspecified

    public var isDirectory: Bool? {
        switch self {
        case .file:
            return false

        case .directory:
            return true

        case .unspecified:
            return nil
        }
    }
}
