import FileTypes

public protocol SegmentConcatenable: Sendable, Codable, Equatable {
    var segments: [PathSegment] { get set }
    var filetype: AnyFileType? { get }
    // var concatenated: String { get }

    func concatenate(
        using separator: String,
        includeFileType: Bool
    ) -> String

    @available(*, message: "superseded by render()")
    func rendered(
        using separator: String,
        asRootPath: Bool,
        includeFileType: Bool
    ) -> String

    func render(
        as relativity: PathRelativity,
        separator: String,
        filetype: Bool
    ) -> String
}
