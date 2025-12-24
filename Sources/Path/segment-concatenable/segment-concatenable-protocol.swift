public protocol SegmentConcatenable: Sendable, Codable {
    var segments: [PathSegment] { get set }
    var filetype: AnyFileType? { get }
    var concatenated: String { get }
    func concatenate(using separator: String) -> String
    func rendered(asRootPath: Bool) -> String
}
