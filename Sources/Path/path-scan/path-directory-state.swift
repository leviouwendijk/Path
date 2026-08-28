public enum PathDirectoryState:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case empty
    case nonempty
}
