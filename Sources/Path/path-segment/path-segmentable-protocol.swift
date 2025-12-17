public protocol PathSegmentable: Sendable, Codable {
    var value: String { get set }
    var type: PathSegmentType? { get set }
}
