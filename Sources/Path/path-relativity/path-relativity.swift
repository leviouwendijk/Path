public enum PathRelativity: String, RawRepresentable, Sendable, Codable {
    case root
    case relative

    var prefix: String? {
        switch self {
        case .root:
            return "/"
        case .relative:
            return nil
        }
    }
}
