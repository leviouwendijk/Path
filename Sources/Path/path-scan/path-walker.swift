import Foundation
import IO

struct PathWalkStatistics {
    let totalDuration: TimeInterval
    let directoryEnumerationDuration: TimeInterval
    let childSortingDuration: TimeInterval
    let metadataInspectionDuration: TimeInterval
    let resultSortingDuration: TimeInterval

    var bookkeepingDuration: TimeInterval {
        max(
            0,
            totalDuration
                - directoryEnumerationDuration
                - childSortingDuration
                - metadataInspectionDuration
                - resultSortingDuration
        )
    }
}

struct PathWalkMeasuredResult {
    let entries: [PathWalkEntry]
    let statistics: PathWalkStatistics
}

private struct PathWalkTimingAccumulator {
    var directoryEnumerationDuration: TimeInterval = 0
    var childSortingDuration: TimeInterval = 0
    var metadataInspectionDuration: TimeInterval = 0
}

public struct PathWalker {
    public let root: URL
    public let configuration: PathWalkConfiguration
    public let fileSystem: FileSystem

    public init(
        root: URL,
        configuration: PathWalkConfiguration = .init(),
        fileSystem: FileSystem = .default
    ) {
        self.root = root.standardizedFileURL
        self.configuration = configuration
        self.fileSystem = fileSystem
    }

    public func walk() throws -> [PathWalkEntry] {
        try measuredWalk().entries
    }

    func measuredWalk() throws -> PathWalkMeasuredResult {
        let startedAt = Date()

        var timings =
            PathWalkTimingAccumulator()

        var out: [PathWalkEntry] = []

        let inspectedRoot = fileSystem.resolve(
            root
        )

        let rootInspectionStartedAt =
            Date()

        let rootMetadata = try FileInspector(
            inspectedRoot
        ).inspect()

        timings.metadataInspectionDuration +=
            Date().timeIntervalSince(
                rootInspectionStartedAt
            )

        guard rootMetadata.existed else {
            return .init(
                entries: [],
                statistics: .init(
                    totalDuration:
                        Date().timeIntervalSince(
                            startedAt
                        ),
                    directoryEnumerationDuration:
                        timings.directoryEnumerationDuration,
                    childSortingDuration:
                        timings.childSortingDuration,
                    metadataInspectionDuration:
                        timings.metadataInspectionDuration,
                    resultSortingDuration: 0
                )
            )
        }

        if rootMetadata.kind != .directory {
            if configuration.emitFiles {
                out.append(
                    makeEntry(
                        url: root,
                        depth: 0,
                        type: .file
                    )
                )
            }

            return .init(
                entries: out,
                statistics: .init(
                    totalDuration:
                        Date().timeIntervalSince(
                            startedAt
                        ),
                    directoryEnumerationDuration:
                        timings.directoryEnumerationDuration,
                    childSortingDuration:
                        timings.childSortingDuration,
                    metadataInspectionDuration:
                        timings.metadataInspectionDuration,
                    resultSortingDuration: 0
                )
            )
        }

        var visited: Set<URL> = []

        try walkDirectory(
            root,
            depth: 0,
            entries: &out,
            visited: &visited,
            emitCurrentDirectory:
                configuration.emitDirectories,
            timings: &timings
        )

        let resultSortingStartedAt =
            Date()

        let sorted = out.sorted {
            $0.url.path < $1.url.path
        }

        let resultSortingDuration =
            Date().timeIntervalSince(
                resultSortingStartedAt
            )

        return .init(
            entries: sorted,
            statistics: .init(
                totalDuration:
                    Date().timeIntervalSince(
                        startedAt
                    ),
                directoryEnumerationDuration:
                    timings.directoryEnumerationDuration,
                childSortingDuration:
                    timings.childSortingDuration,
                metadataInspectionDuration:
                    timings.metadataInspectionDuration,
                resultSortingDuration:
                    resultSortingDuration
            )
        )
    }
}

private extension PathWalker {
    func walkDirectory(
        _ directory: URL,
        depth: Int,
        entries: inout [PathWalkEntry],
        visited: inout Set<URL>,
        emitCurrentDirectory: Bool,
        timings: inout PathWalkTimingAccumulator
    ) throws {
        let standardizedDirectory =
            directory.standardizedFileURL

        let visitKey =
            resolvedVisitKey(
                for: standardizedDirectory
            )

        guard visited.insert(
            visitKey
        ).inserted else {
            return
        }

        if emitCurrentDirectory {
            entries.append(
                makeEntry(
                    url: standardizedDirectory,
                    depth: depth,
                    type: .directory
                )
            )
        }

        if let maxDepth =
            configuration.maxDepth,
           depth >= maxDepth {
            return
        }

        let enumerationStartedAt =
            Date()

        let children =
            try fileSystem
            .directory
            .contents(
                standardizedDirectory
            )

        timings.directoryEnumerationDuration +=
            Date().timeIntervalSince(
                enumerationStartedAt
            )

        let childSortingStartedAt =
            Date()

        let sortedChildren =
            children.sorted {
                $0.path < $1.path
            }

        timings.childSortingDuration +=
            Date().timeIntervalSince(
                childSortingStartedAt
            )

        for child in sortedChildren {
            if !configuration.includeHidden,
               child.lastPathComponent.hasPrefix(
                    "."
               ) {
                continue
            }

            let childInspectionStartedAt =
                Date()

            let childMetadata =
                try FileInspector(
                    child
                )
                .inspect()

            timings.metadataInspectionDuration +=
                Date().timeIntervalSince(
                    childInspectionStartedAt
                )

            guard childMetadata.existed else {
                continue
            }

            let targetURL: URL
            let targetMetadata: FileMetadataSnapshot

            if childMetadata.kind == .symlink {
                guard configuration.followSymlinks else {
                    continue
                }

                targetURL =
                    fileSystem.resolve(
                        child
                    )

                let targetInspectionStartedAt =
                    Date()

                targetMetadata =
                    try FileInspector(
                        targetURL
                    )
                    .inspect()

                timings.metadataInspectionDuration +=
                    Date().timeIntervalSince(
                        targetInspectionStartedAt
                    )
            } else {
                targetURL =
                    child.standardizedFileURL

                targetMetadata =
                    childMetadata
            }

            guard targetMetadata.existed else {
                continue
            }

            switch targetMetadata.kind {
            case .directory:
                try walkDirectory(
                    targetURL,
                    depth: depth + 1,
                    entries: &entries,
                    visited: &visited,
                    emitCurrentDirectory:
                        configuration.emitDirectories,
                    timings: &timings
                )

            case .file:
                if configuration.emitFiles {
                    entries.append(
                        makeEntry(
                            url: targetURL,
                            depth: depth + 1,
                            type: .file
                        )
                    )
                }

            case .symlink, .other, nil:
                continue
            }
        }
    }

    func makeEntry(
        url: URL,
        depth: Int,
        type: PathSegmentType
    ) -> PathWalkEntry {
        let terminalHint: PathTerminalHint = switch type {
        case .directory:
            .directory
        case .file:
            .file
        }

        let absolutePath = StandardPath(
            fileURL: url,
            terminalHint: terminalHint,
            inferFileType: type == .file
        )

        let relativePath = relativePath(
            from: absolutePath,
            under: StandardPath(
                fileURL: root,
                terminalHint: .directory,
                inferFileType: false
            )
        )

        return PathWalkEntry(
            url: url,
            absolutePath: absolutePath,
            relativePath: relativePath,
            depth: depth,
            type: type
        )
    }

    func relativePath(
        from candidate: StandardPath,
        under rootPath: StandardPath
    ) -> StandardPath {
        candidate.relative(to: rootPath) ?? candidate
    }

    // func relativePath(
    //     from candidate: StandardPath,
    //     under rootPath: StandardPath
    // ) -> StandardPath {
    //     let rootSegments = rootPath.segments.map(\.value)
    //     let candidateSegments = candidate.segments.map(\.value)

    //     guard
    //         candidateSegments.count >= rootSegments.count,
    //         Array(candidateSegments.prefix(rootSegments.count)) == rootSegments
    //     else {
    //         return candidate
    //     }

    //     let relativeSegments = Array(
    //         candidate.segments.dropFirst(rootSegments.count)
    //     )

    //     return StandardPath(
    //         relativeSegments,
    //         filetype: candidate.filetype
    //     )
    // }

    func resolvedVisitKey(
        for url: URL
    ) -> URL {
        configuration.followSymlinks
            ? fileSystem.resolve(
                url
            )
            : url.standardizedFileURL
    }
}
