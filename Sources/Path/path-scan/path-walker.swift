import Foundation
import IO

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
        var out: [PathWalkEntry] = []

        let inspectedRoot = fileSystem.resolve(
            root
        )

        let rootMetadata = try FileInspector(
            inspectedRoot
        ).inspect()

        guard rootMetadata.existed else {
            return []
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

            return out
        }

        var visited: Set<URL> = []
        try walkDirectory(
            root,
            depth: 0,
            entries: &out,
            visited: &visited,
            emitCurrentDirectory: configuration.emitDirectories
        )

        return out.sorted { $0.url.path < $1.url.path }
    }
}

private extension PathWalker {
    func walkDirectory(
        _ directory: URL,
        depth: Int,
        entries: inout [PathWalkEntry],
        visited: inout Set<URL>,
        emitCurrentDirectory: Bool
    ) throws {
        let standardizedDirectory = directory.standardizedFileURL
        let visitKey = resolvedVisitKey(for: standardizedDirectory)

        guard visited.insert(visitKey).inserted else {
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

        if let maxDepth = configuration.maxDepth, depth >= maxDepth {
            return
        }

        let children = try fileSystem.directory.contents(
            standardizedDirectory
        )

        for child in children.sorted(by: { $0.path < $1.path }) {
            if !configuration.includeHidden,
               child.lastPathComponent.hasPrefix(".") {
                continue
            }

            let childMetadata = try FileInspector(
                child
            ).inspect()

            guard childMetadata.existed else {
                continue
            }

            let targetURL: URL
            let targetMetadata: FileMetadataSnapshot

            if childMetadata.kind == .symlink {
                guard configuration.followSymlinks else {
                    continue
                }

                targetURL = fileSystem.resolve(
                    child
                )

                targetMetadata = try FileInspector(
                    targetURL
                ).inspect()
            } else {
                targetURL = child.standardizedFileURL
                targetMetadata = childMetadata
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
                    emitCurrentDirectory: configuration.emitDirectories
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
