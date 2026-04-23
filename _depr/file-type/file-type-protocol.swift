public protocol FileType:
    Sendable,
    Codable,
    CaseIterable,
    RawRepresentable
    where RawValue == String
{
    init(filename: String) throws
    var component: String { get }
}
