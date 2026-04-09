import Foundation

public enum PathPresentationStyle: Sendable, Codable, Equatable {
    case full
    case relative(
        to: StandardPath,
        marker: String = "."
    )
    case dropFirst(Int)
    case middleEllipsis(
        keepFirst: Int,
        keepLast: Int,
        marker: String = "…"
    )
}

public struct PathPresentationOptions: Sendable, Codable, Equatable {
    public var style: PathPresentationStyle
    public var separator: String
    public var filetype: Bool
    public var showOmittedCount: Bool

    public init(
        style: PathPresentationStyle = .full,
        separator: String = "/",
        filetype: Bool = true,
        showOmittedCount: Bool = false
    ) {
        self.style = style
        self.separator = separator
        self.filetype = filetype
        self.showOmittedCount = showOmittedCount
    }
}
