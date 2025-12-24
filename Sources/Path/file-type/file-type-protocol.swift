public protocol FileType: 
    Sendable,
    Codable,
    CaseIterable,
    RawRepresentable 
    where RawValue == String 
{
    var component: String { get }
}
