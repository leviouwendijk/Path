import Foundation

extension StandardPath {
    private static func fromFileURL(_ url: URL) -> StandardPath {
        let standardized = url.standardizedFileURL

        // "/Users/levi" -> ["/", "Users", "levi"] -> ["Users", "levi"]
        let comps = standardized.pathComponents
            .filter { $0 != "/" }
            .filter { !$0.isEmpty }

        return StandardPath(comps)
    }

    // Useful if you ever want "just /"
    public static let root: StandardPath = StandardPath()

    // Stable during a process lifetime: good as `let`
    public static let home: StandardPath =
        fromFileURL(FileManager.default.homeDirectoryForCurrentUser)

    public static let tmp: StandardPath =
        fromFileURL(FileManager.default.temporaryDirectory)

    // CWD can change, computed
    public static var cwd: StandardPath {
        fromFileURL(URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
    }

    // optionals
    public static var documents: StandardPath? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first.map(fromFileURL)
    }

    public static var desktop: StandardPath? {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first.map(fromFileURL)
    }

    public static var downloads: StandardPath? {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first.map(fromFileURL)
    }

    public static var library: StandardPath? {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first.map(fromFileURL)
    }

    public static var appSupport: StandardPath? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first.map(fromFileURL)
    }

    public static var caches: StandardPath? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first.map(fromFileURL)
    }
}
