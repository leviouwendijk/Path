import Foundation

public struct ResolvedPathReference: Sendable, Equatable, Hashable {
    public let url: URL
    public let terminalHint: PathTerminalHint

    public init(
        url: URL,
        terminalHint: PathTerminalHint = .unspecified
    ) {
        self.url = url.standardizedFileURL
        self.terminalHint = terminalHint
    }

    public var path: String {
        let resolved = url.path

        guard terminalHint == .directory,
              !resolved.hasSuffix("/") else {
            return resolved
        }

        return resolved + "/"
    }

    public var standard_path: StandardPath {
        StandardPath(
            fileURL: url,
            terminalHint: terminalHint,
            inferFileType: terminalHint == .file
        )
    }
}
