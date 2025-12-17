public protocol SegmentConcatenable: Sendable, Codable {
    var segments: [PathSegment] { get set }
    var concatenated: String { get }
    func rendered(asRootPath: Bool) -> String
}
