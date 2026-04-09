import Foundation

public enum PathAncestorSearch {
    public static func ancestors(
        startingAt start: URL,
        treatingStartAsDirectory: Bool = true,
        includingStart: Bool = true,
        maxDepth: Int? = nil
    ) -> [URL] {
        var out: [URL] = []

        var current = normalizedStart(
            start,
            treatingAsDirectory: treatingStartAsDirectory
        )

        if !includingStart {
            current = current.deletingLastPathComponent()
        }

        var depth = 0

        while true {
            out.append(current)

            if let maxDepth, depth >= maxDepth {
                break
            }

            let parent = current.deletingLastPathComponent()

            if parent.path == current.path {
                break
            }

            current = parent
            depth += 1
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
        for candidate in ancestors(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth
        ) {
            if try predicate(candidate) {
                return candidate
            }
        }

        return nil
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
        fileManager: FileManager = .default
    ) -> URL? {
        nearestAncestor(
            startingAt: start,
            treatingStartAsDirectory: treatingStartAsDirectory,
            includingStart: includingStart,
            maxDepth: maxDepth
        ) { candidate in
            for name in names {
                var isDirectory: ObjCBool = false
                let target = candidate.appendingPathComponent(name)

                if fileManager.fileExists(
                    atPath: target.path,
                    isDirectory: &isDirectory
                ) {
                    return true
                }
            }

            return false
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
