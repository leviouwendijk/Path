public protocol PathSegmentable: Sendable, Codable, Equatable {
    var value: String { get set }
    var type: PathSegmentType? { get set }
}
