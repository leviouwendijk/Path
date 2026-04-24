import Foundation

public struct PathAncestorDirectoryMatch: Sendable, Codable, Equatable, Hashable {
    public let ancestor: StandardPath
    public let directory: StandardPath

    public init(
        ancestor: StandardPath,
        directory: StandardPath
    ) {
        self.ancestor = ancestor
        self.directory = directory
    }

    public var ancestorURL: URL {
        ancestor.directory_url
    }

    public var directoryURL: URL {
        directory.directory_url
    }
}

public enum PathLookup {
    public static func nearestAncestorDirectory(
        named name: String,
        from start: StandardPath
    ) -> PathAncestorDirectoryMatch? {
        let name = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard isSinglePathComponent(
            name
        ) else {
            return nil
        }

        var current = PathNormalization.root(
            start
        )

        while true {
            let candidate = StandardPath(
                from: current,
                name,
                filetype: nil
            )

            if PathExistence.isDirectory(
                url: candidate.directory_url
            ) {
                return .init(
                    ancestor: current,
                    directory: candidate
                )
            }

            guard let parent = current.parentDirectoryPath else {
                return nil
            }

            current = parent
        }
    }

    public static func nearestAncestorDirectory(
        named name: String,
        from startURL: URL
    ) -> PathAncestorDirectoryMatch? {
        nearestAncestorDirectory(
            named: name,
            from: StandardPath(
                fileURL: startURL,
                terminalHint: .directory,
                inferFileType: false
            )
        )
    }
}

private extension PathLookup {
    static func isSinglePathComponent(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty else {
            return false
        }

        guard !value.contains("/") else {
            return false
        }

        return true
    }
}

private extension StandardPath {
    var parentDirectoryPath: StandardPath? {
        guard !segments.isEmpty else {
            return nil
        }

        return StandardPath(
            Array(
                segments.dropLast()
            ),
            filetype: nil
        )
    }
}
