import Foundation

public struct PathWalker {
    public let root: URL
    public let configuration: PathWalkConfiguration
    public let fileManager: FileManager

    public init(
        root: URL,
        configuration: PathWalkConfiguration = .init(),
        fileManager: FileManager = .default
    ) {
        self.root = root.standardizedFileURL
        self.configuration = configuration
        self.fileManager = fileManager
    }

    public func walk() throws -> [PathWalkEntry] {
        var out: [PathWalkEntry] = []

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(
            atPath: root.path,
            isDirectory: &isDirectory
        ) else {
            return []
        }

        if !isDirectory.boolValue {
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

        let children = try fileManager.contentsOfDirectory(
            at: standardizedDirectory,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .isSymbolicLinkKey,
                .isHiddenKey
            ],
            options: []
        )

        for child in children.sorted(by: { $0.path < $1.path }) {
            if !configuration.includeHidden,
               child.lastPathComponent.hasPrefix(".") {
                continue
            }

            let values = try child.resourceValues(forKeys: [
                .isDirectoryKey,
                .isSymbolicLinkKey
            ])

            if values.isSymbolicLink == true,
               !configuration.followSymlinks {
                continue
            }

            let targetURL = configuration.followSymlinks
                ? child.resolvingSymlinksInPath().standardizedFileURL
                : child.standardizedFileURL

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(
                atPath: targetURL.path,
                isDirectory: &isDirectory
            ) else {
                continue
            }

            if isDirectory.boolValue {
                try walkDirectory(
                    targetURL,
                    depth: depth + 1,
                    entries: &entries,
                    visited: &visited,
                    emitCurrentDirectory: configuration.emitDirectories
                )
            } else if configuration.emitFiles {
                entries.append(
                    makeEntry(
                        url: targetURL,
                        depth: depth + 1,
                        type: .file
                    )
                )
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
            ? url.resolvingSymlinksInPath().standardizedFileURL
            : url.standardizedFileURL
    }
}
