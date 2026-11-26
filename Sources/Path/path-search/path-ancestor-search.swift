import Foundation
import IO

public enum PathAncestorSearch {
    public static func ancestors(
        startingAt start: URL,
        treatingStartAsDirectory: Bool = true,
        includingStart: Bool = true,
        maxDepth: Int? = nil,
        boundary: URL? = nil
    ) -> [URL] {
        var out: [URL] = []

        walk(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth,
            boundary: boundary
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
        boundary: URL? = nil,
        where predicate: (URL) throws -> Bool
    ) rethrows -> URL? {
        var found: URL?

        try walk(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth,
            boundary: boundary
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
        boundary: URL? = nil,
        collect: (URL) throws -> [T]
    ) rethrows -> [(directory: URL, matches: [T])] {
        var results: [(directory: URL, matches: [T])] = []

        for candidate in ancestors(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth,
            boundary: boundary
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
        boundary: URL? = nil,
        fileSystem: FileSystem = .default
    ) -> URL? {
        nearestAncestor(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth,
            boundary: boundary
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

    /// `relative` under the nearest ancestor where it exists, e.g. `env/keys/app/key.pem`
    /// found from a binary deep inside the checkout. Climbing is the point here, so this
    /// is for paths the program is configured with, never for paths a request supplies.
    /// The relative path itself may not climb (`..`) or be absolute.
    public static func resolvingUpwards(
        _ relative: String,
        startingAt start: URL,
        treatingStartAsDirectory: Bool = true,
        boundary: URL? = nil,
        fileSystem: FileSystem = .default
    ) -> URL? {
        let components = relative.split(separator: "/", omittingEmptySubsequences: true)
        guard !relative.hasPrefix("/"),
              !components.isEmpty,
              !components.contains(where: { $0 == ".." }) else {
            return nil
        }
        return nearestAncestorContainingAny(
            [relative],
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            boundary: boundary,
            fileSystem: fileSystem
        )
        .map { $0.appendingPathComponent(relative) }
    }

    /// Visits the start and each parent up to the filesystem root (or `boundary`, which
    /// is visited last; a start outside `boundary` visits nothing), until `visit` returns true.
    /// The parent of `/` is standardized back to `/`, which ends the walk: a raw
    /// `deletingLastPathComponent()` would keep producing `/..`, `/../..`, … forever.
    private static func walk(
        startingAt start: URL,
        treatingStartAsDirectory: Bool,
        includingStart: Bool,
        maxDepth: Int?,
        boundary: URL? = nil,
        visit: (URL) throws -> Bool
    ) rethrows {
        var current = normalizedStart(
            start,
            treatingAsDirectory: treatingStartAsDirectory
        )

        if !includingStart {
            current = current.deletingLastPathComponent().standardizedFileURL
        }

        let limit = boundary?.standardizedFileURL.path
        if let limit, !isWithin(current.path, limit) {
            return
        }

        var depth = 0

        while true {
            if try visit(current) {
                return
            }

            if let maxDepth, depth >= maxDepth {
                return
            }

            if let limit, current.path == limit {
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

    private static func isWithin(
        _ path: String,
        _ limit: String
    ) -> Bool {
        limit == "/" || path == limit || path.hasPrefix(limit + "/")
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
