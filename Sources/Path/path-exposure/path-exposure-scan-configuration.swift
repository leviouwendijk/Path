public enum PathExposureTruncationReason: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case max_depth
    case max_entries
    case max_findings
    case io_error
}

public struct PathExposureScanConfiguration: Sendable, Codable, Equatable, Hashable {
    public var maxDepth: Int?
    public var maxEntries: Int?
    public var maxFindings: Int?
    public var maxCollateralExamples: Int
    public var includeHidden: Bool
    public var followSymlinks: Bool
    public var emitDirectories: Bool
    public var emitFiles: Bool
    public var collectMetadata: Bool

    public init(
        maxDepth: Int? = nil,
        maxEntries: Int? = 10_000,
        maxFindings: Int? = 500,
        maxCollateralExamples: Int = 5,
        includeHidden: Bool = true,
        followSymlinks: Bool = false,
        emitDirectories: Bool = true,
        emitFiles: Bool = true,
        collectMetadata: Bool = false
    ) {
        self.maxDepth = maxDepth
        self.maxEntries = maxEntries
        self.maxFindings = maxFindings
        self.maxCollateralExamples = max(0, maxCollateralExamples)
        self.includeHidden = includeHidden
        self.followSymlinks = followSymlinks
        self.emitDirectories = emitDirectories
        self.emitFiles = emitFiles
        self.collectMetadata = collectMetadata
    }

    public static let `default` = Self()
}

public extension PathExposureScanConfiguration {
    var walkConfiguration: PathWalkConfiguration {
        .init(
            maxDepth: maxDepth,
            includeHidden: includeHidden,
            followSymlinks: followSymlinks,
            emitDirectories: emitDirectories,
            emitFiles: emitFiles
        )
    }
}
