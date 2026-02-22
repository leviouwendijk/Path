import Foundation

public protocol StandardEnvironmentPath: Sendable {
    var standard_path: StandardPath { get }
}

public extension StandardEnvironmentPath {
    /// The URL represented by `standard_path` (includes filetype if present).
    var root_url: URL {
        standard_path
            .root_url(includeFileType: true)
            .standardizedFileURL
    }

    /// Treat `standard_path` as a directory (ignores filetype).
    var directory_url: URL {
        standard_path
            .root_url(includeFileType: false)
            .standardizedFileURL
    }

    /// Convenience for “put a pdf named X in this directory”.
    func pdf_url(filename: String) -> URL {
        directory_url
            .appendingPathComponent("\(filename).pdf")
            .standardizedFileURL
    }
}

public extension StandardEnvironmentPath {
    var root_string: String {
        standard_path.rendered(asRootPath: true, includeFileType: true)
    }

    var directory_string: String {
        standard_path.rendered(asRootPath: true, includeFileType: false)
    }
}
