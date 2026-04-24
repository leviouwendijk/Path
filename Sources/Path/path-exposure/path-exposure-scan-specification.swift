public struct PathExposureScanSpecification: Sendable, Codable, Equatable, Hashable {
    public var root: StandardPath
    public var baselinePolicy: PathAccessPolicy
    public var proposedPolicy: PathAccessPolicy
    public var sensitivity: PathSensitivityProfile
    public var configuration: PathExposureScanConfiguration

    public init(
        root: StandardPath,
        baselinePolicy: PathAccessPolicy = .init(default: .deny),
        proposedPolicy: PathAccessPolicy = .allowAll,
        sensitivity: PathSensitivityProfile = .agenticConservative,
        configuration: PathExposureScanConfiguration = .default
    ) {
        self.root = PathNormalization.root(root)
        self.baselinePolicy = baselinePolicy
        self.proposedPolicy = proposedPolicy
        self.sensitivity = sensitivity
        self.configuration = configuration
    }
}
