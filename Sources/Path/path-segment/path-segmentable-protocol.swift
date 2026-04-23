public protocol PathSegmentable: Sendable, Codable, Equatable, Hashable {
    var value: String { get set }
    var type: PathSegmentType? { get set }
}
