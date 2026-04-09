public enum PathScan {
    public static func compile(
        _ specification: PathScanSpecification,
        relativeTo anchor: PathAnchor = .cwd
    ) -> CompiledPathScanPlan {
        PathScanCompiler.compile(
            specification,
            relativeTo: anchor
        )
    }

    public static func scan(
        _ specification: PathScanSpecification,
        relativeTo anchor: PathAnchor = .cwd,
        configuration: PathWalkConfiguration = .init()
    ) throws -> PathScanResult {
        try PathScanner.scan(
            compile(
                specification,
                relativeTo: anchor
            ),
            configuration: configuration
        )
    }

    public static func scan(
        _ plan: CompiledPathScanPlan,
        configuration: PathWalkConfiguration = .init()
    ) throws -> PathScanResult {
        try PathScanner.scan(
            plan,
            configuration: configuration
        )
    }
}
