import Path

public enum ParsedPathScan {
    public static func specification(
        includes: [String] = [],
        excludes: [String] = []
    ) throws -> PathScanSpecification {
        PathScanSpecification(
            includes: try includes.map(PathParse.expression),
            excludes: try excludes.map(PathParse.expression)
        )
    }

    public static func scan(
        includes: [String] = [],
        excludes: [String] = [],
        relativeTo anchor: PathAnchor = .cwd,
        configuration: PathWalkConfiguration = .init()
    ) throws -> PathScanResult {
        try PathScan.scan(
            specification(
                includes: includes,
                excludes: excludes
            ),
            relativeTo: anchor,
            configuration: configuration
        )
    }
}

// public enum ParsedPathScan {
//     public static func specification(
//         includes: [String] = [],
//         excludes: [String] = [],
//         selections: [String] = []
//     ) throws -> PathScanSpecification {
//         PathScanSpecification(
//             includes: try includes.map(PathParse.expression),
//             excludes: try excludes.map(PathParse.expression),
//             selections: try selections.map(PathParse.selectionExpression)
//         )
//     }

//     public static func scan(
//         includes: [String] = [],
//         excludes: [String] = [],
//         selections: [String] = [],
//         relativeTo anchor: PathAnchor = .cwd,
//         configuration: PathWalkConfiguration = .init()
//     ) throws -> PathScanResult {
//         try PathScan.scan(
//             specification(
//                 includes: includes,
//                 excludes: excludes,
//                 selections: selections
//             ),
//             relativeTo: anchor,
//             configuration: configuration
//         )
//     }
// }
