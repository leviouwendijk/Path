public struct PathWalkConfiguration: Sendable, Codable, Equatable {
    public var maxDepth: Int?
    public var includeHidden: Bool
    public var followSymlinks: Bool
    public var emitDirectories: Bool
    public var emitFiles: Bool

    public init(
        maxDepth: Int? = nil,
        includeHidden: Bool = false,
        followSymlinks: Bool = false,
        emitDirectories: Bool = true,
        emitFiles: Bool = true
    ) {
        self.maxDepth = maxDepth
        self.includeHidden = includeHidden
        self.followSymlinks = followSymlinks
        self.emitDirectories = emitDirectories
        self.emitFiles = emitFiles
    }
}
