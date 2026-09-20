import Foundation
import IO
import Primitives

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

private struct PathWalkExpansionValue {
    let source_url: URL
    let url: URL
    let type: PathSegmentType
}

private enum PathWalkExpansionIdentity: Hashable {
    case directory(URL)
    case file_source(URL)
}

public struct PathWalker {
    public let root: URL
    public let configuration: PathWalkConfiguration
    public let fileSystem: FileSystem

    private let rootPath: StandardPath

    public init(
        root: URL,
        configuration: PathWalkConfiguration = .init(),
        fileSystem: FileSystem = .default
    ) {
        let standardizedRoot =
            root.standardizedFileURL

        self.root =
            standardizedRoot

        self.configuration =
            configuration

        self.fileSystem =
            fileSystem

        self.rootPath =
            StandardPath(
                fileURL: standardizedRoot,
                terminalHint: .directory,
                inferFileType: false
            )
    }

    public func walk() throws -> [PathWalkEntry] {
        try measuredWalk().entries
    }

    func measuredWalk() throws -> PathWalkMeasuredResult {
        let startedAt = Date()

        var timings =
            PathWalkTimingAccumulator()

        var directory_is_empty: [URL: Bool] = [:]
        var out: [PathWalkEntry] = []

        let inspectedRoot = fileSystem.resolve(
            root
        )

        let rootInspectionStartedAt =
            Date()

        let rootMetadata = try FileInspector(
            inspectedRoot,
            fileSystem: fileSystem
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

        let expansion = TreeExpansion<PathWalkExpansionValue>(
            roots: [
                .init(
                    source_url: root,
                    url: root,
                    type: .directory
                ),
            ]
        ) { located in
            try self.expansion_children(
                of: located.value,
                timings: &timings,
                directory_is_empty: &directory_is_empty
            )
        }

        let limits = try TreeTraversalLimits(
            maximum_depth: configuration.maxDepth
        )

        let revisit = TreeExpansionRevisitPolicy<PathWalkExpansionValue>.global(
            identity: { value -> PathWalkExpansionIdentity in
                switch value.type {
                case .directory:
                    return .directory(
                        self.resolvedVisitKey(
                            for: value.url
                        )
                    )

                case .file:
                    return .file_source(
                        value.source_url
                    )
                }
            }
        )

        var iterator = expansion.walk(
            .depth_first_preorder,
            limits: limits,
            revisit: revisit
        )
        .makeIterator()

        while let located = try iterator.next() {
            let value = located.value

            switch value.type {
            case .directory:
                guard configuration.emitDirectories else {
                    continue
                }

            case .file:
                guard configuration.emitFiles else {
                    continue
                }
            }

            out.append(
                makeEntry(
                    url: value.url,
                    depth: located.address.depth,
                    type: value.type
                )
            )
        }

        out = try applying_directory_state(
            to: out,
            known_empty: directory_is_empty
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
    func expansion_children(
        of parent: PathWalkExpansionValue,
        timings: inout PathWalkTimingAccumulator,
        directory_is_empty: inout [URL: Bool]
    ) throws -> [PathWalkExpansionValue] {
        guard parent.type == .directory else {
            return []
        }

        let enumerationStartedAt =
            Date()

        let enumerationOptions: FileManager.DirectoryEnumerationOptions =
            configuration.includeHidden
                ? []
                : .skipsHiddenFiles

        let children =
            try fileSystem
            .directory
            .entries(
                parent.url,
                options: enumerationOptions
            )

        if configuration.emitDirectories,
           configuration.directoryState != nil {
            let isEmpty: Bool

            if !children.isEmpty || configuration.includeHidden {
                isEmpty = children.isEmpty
            } else {
                isEmpty = try DirectoryInspector(
                    parent.url,
                    fileSystem: fileSystem
                ).isEmpty()
            }

            directory_is_empty[
                parent.url.standardizedFileURL
            ] = isEmpty
        }

        timings.directoryEnumerationDuration +=
            Date().timeIntervalSince(
                enumerationStartedAt
            )

        let childSortingStartedAt =
            Date()

        let sortedChildren =
            children.sorted {
                $0.url.path
                    < $1.url.path
            }

        timings.childSortingDuration +=
            Date().timeIntervalSince(
                childSortingStartedAt
            )

        var discovered: [PathWalkExpansionValue] = []
        discovered.reserveCapacity(
            sortedChildren.count
        )

        for childEntry in sortedChildren {
            let child =
                childEntry.url

            let targetURL: URL
            let targetKind: FileKind

            if childEntry.kind == .symlink {
                guard configuration.followSymlinks else {
                    continue
                }

                targetURL =
                    fileSystem.resolve(
                        child
                    )

                let targetInspectionStartedAt =
                    Date()

                let targetMetadata =
                    try FileInspector(
                        targetURL,
                        fileSystem: fileSystem
                    )
                    .inspect()

                timings.metadataInspectionDuration +=
                    Date().timeIntervalSince(
                        targetInspectionStartedAt
                    )

                guard
                    targetMetadata.existed,
                    let kind =
                        targetMetadata.kind
                else {
                    continue
                }

                targetKind =
                    kind
            } else {
                targetURL =
                    child

                targetKind =
                    childEntry.kind
            }

            switch targetKind {
            case .directory:
                discovered.append(
                    .init(
                        source_url: child,
                        url: targetURL,
                        type: .directory
                    )
                )

            case .file:
                discovered.append(
                    .init(
                        source_url: child,
                        url: targetURL,
                        type: .file
                    )
                )

            case .symlink, .other:
                continue
            }
        }

        return discovered
    }

    func applying_directory_state(
        to entries: [PathWalkEntry],
        known_empty: [URL: Bool]
    ) throws -> [PathWalkEntry] {
        guard let state = configuration.directoryState,
              configuration.emitDirectories else {
            return entries
        }

        return try entries.filter { entry in
            guard entry.type == .directory else {
                return true
            }

            let key = entry.url.standardizedFileURL
            let isEmpty: Bool

            if let known = known_empty[key] {
                isEmpty = known
            } else {
                isEmpty = try DirectoryInspector(
                    entry.url,
                    fileSystem: fileSystem
                ).isEmpty()
            }

            switch state {
            case .empty:
                return isEmpty

            case .nonempty:
                return !isEmpty
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

        let relativePath =
            relativePath(
                from: absolutePath
            )

        return PathWalkEntry(
            standardizedURL: url,
            absolutePath: absolutePath,
            relativePath: relativePath,
            depth: depth,
            type: type
        )
    }

    func relativePath(
        from candidate: StandardPath
    ) -> StandardPath {
        let rootSegments =
            rootPath.segments

        guard candidate.segments.count
                >= rootSegments.count
        else {
            return candidate
        }

        for index in rootSegments.indices {
            guard candidate
                    .segments[index]
                    .value
                    == rootSegments[index].value
            else {
                return candidate
            }
        }

        return StandardPath(
            Array(
                candidate
                    .segments
                    .dropFirst(
                        rootSegments.count
                    )
            ),
            filetype:
                candidate.filetype
        )
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
            : url
    }
}
