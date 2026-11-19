import Foundation
import IO

public enum PathAncestorSearch {
    public static func ancestors(
        startingAt start: URL,
        treatingStartAsDirectory: Bool = true,
        includingStart: Bool = true,
        maxDepth: Int? = nil
    ) -> [URL] {
        var out: [URL] = []

        walk(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth
        ) { candidate in
            out.append(candidate)
            return false
        }

        return out
    }

    public static func nearestAncestor(
        startingAt start: URL,
        treatingStartAsDirectory: Bool = true,
        includingStart: Bool = true,
        maxDepth: Int? = nil,
        where predicate: (URL) throws -> Bool
    ) rethrows -> URL? {
        var found: URL?

        try walk(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth
        ) { candidate in
            guard try predicate(candidate) else {
                return false
            }

            found = candidate
            return true
        }

        return found
    }

    public static func collectUpwards<T>(
        startingAt start: URL,
        treatingStartAsDirectory: Bool = true,
        includingStart: Bool = true,
        maxDepth: Int? = nil,
        collect: (URL) throws -> [T]
    ) rethrows -> [(directory: URL, matches: [T])] {
        var results: [(directory: URL, matches: [T])] = []

        for candidate in ancestors(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth
        ) {
            let matches = try collect(candidate)

            if !matches.isEmpty {
                results.append((directory: candidate, matches: matches))
            }
        }

        return results
    }

    public static func nearestAncestorContainingAny(
        _ names: [String],
        startingAt start: URL,
        treatingStartAsDirectory: Bool = true,
        includingStart: Bool = true,
        maxDepth: Int? = nil,
        fileSystem: FileSystem = .default
    ) -> URL? {
        nearestAncestor(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth
        ) { candidate in
            for name in names {
                let target = candidate.appendingPathComponent(
                    name
                )

                if fileSystem.exists(
                    target
                ) {
                    return true
                }
            }

            return false
        }
    }

    /// Visits the start and each parent up to the filesystem root, until `visit` returns true.
    /// The parent of `/` is standardized back to `/`, which ends the walk: a raw
    /// `deletingLastPathComponent()` would keep producing `/..`, `/../..`, … forever.
    private static func walk(
        startingAt start: URL,
        treatingStartAsDirectory: Bool,
        includingStart: Bool,
        maxDepth: Int?,
        visit: (URL) throws -> Bool
    ) rethrows {
        var current = normalizedStart(
            start,
            treatingAsDirectory: treatingStartAsDirectory
        )

        if !includingStart {
            current = current.deletingLastPathComponent().standardizedFileURL
        }

        var depth = 0

        while true {
            if try visit(current) {
                return
            }

            if let maxDepth, depth >= maxDepth {
                return
            }

            let parent = current.deletingLastPathComponent().standardizedFileURL

            if parent.path == current.path {
                return
            }

            current = parent
            depth += 1
        }
    }

    private static func normalizedStart(
        _ start: URL,
        treatingAsDirectory: Bool
    ) -> URL {
        let standardized = start.standardizedFileURL

        if treatingAsDirectory {
            return standardized
        }

        return standardized.deletingLastPathComponent()
    }
}
