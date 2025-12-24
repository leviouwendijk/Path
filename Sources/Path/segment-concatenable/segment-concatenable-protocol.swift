public protocol SegmentConcatenable: Sendable, Codable {
    var segments: [PathSegment] { get set }
    var filetype: AnyFileType? { get }
    // var concatenated: String { get }

    func concatenate(
        using separator: String,
        includeFileType: Bool
    ) -> String

    func rendered(
        using separator: String,
        asRootPath: Bool,
        includeFileType: Bool
    ) -> String
}
