import IO

public enum PathSegmentType: String, RawRepresentable, Sendable, Codable {
    case directory
    case file

    public init?(
        _ kind: FileKind
    ) {
        switch kind {
        case .directory:
            self = .directory

        case .file:
            self = .file

        case .symlink, .other:
            return nil
        }
    }
}
