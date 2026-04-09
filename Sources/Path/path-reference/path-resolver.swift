import Foundation

public enum PathResolveError: Error, LocalizedError, Sendable, Equatable {
    case emptyInput

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Path reference cannot be empty"
        }
    }
}

public enum PathResolver {
    public static func resolve(
        _ raw: String,
        relativeTo anchor: PathAnchor = .cwd,
        terminalHint: PathTerminalHint = .unspecified
    ) throws -> ResolvedPathReference {
        let trimmed = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            throw PathResolveError.emptyInput
        }

        let inferredHint = inferredTerminalHint(
            from: trimmed,
            explicit: terminalHint
        )

        if trimmed == "~" || trimmed == "$HOME" {
            return .init(
                url: StandardPath.home.directory_url,
                terminalHint: .directory
            )
        }

        if trimmed == "$CWD" {
            return .init(
                url: StandardPath.cwd.directory_url,
                terminalHint: .directory
            )
        }

        if let remainder = trimmed.removingPrefix("~/") {
            return resolveRelative(
                remainder,
                baseURL: StandardPath.home.directory_url,
                terminalHint: inferredHint
            )
        }

        if let remainder = trimmed.removingPrefix("$HOME/") {
            return resolveRelative(
                remainder,
                baseURL: StandardPath.home.directory_url,
                terminalHint: inferredHint
            )
        }

        if let remainder = trimmed.removingPrefix("$CWD/") {
            return resolveRelative(
                remainder,
                baseURL: StandardPath.cwd.directory_url,
                terminalHint: inferredHint
            )
        }

        if trimmed.hasPrefix("/") {
            return .init(
                url: URL(
                    fileURLWithPath: trimmed,
                    isDirectory: inferredHint == .directory
                ),
                terminalHint: inferredHint
            )
        }

        return resolveRelative(
            trimmed,
            baseURL: anchor.directory_url,
            terminalHint: inferredHint
        )
    }

    public static func resolveURL(
        _ raw: String,
        relativeTo anchor: PathAnchor = .cwd,
        terminalHint: PathTerminalHint = .unspecified
    ) throws -> URL {
        try resolve(
            raw,
            relativeTo: anchor,
            terminalHint: terminalHint
        ).url
    }

    public static func resolveString(
        _ raw: String,
        relativeTo anchor: PathAnchor = .cwd,
        terminalHint: PathTerminalHint = .unspecified
    ) throws -> String {
        try resolve(
            raw,
            relativeTo: anchor,
            terminalHint: terminalHint
        ).path
    }

    public static func resolveStandardPath(
        _ raw: String,
        relativeTo anchor: PathAnchor = .cwd,
        terminalHint: PathTerminalHint = .unspecified
    ) throws -> StandardPath {
        try resolve(
            raw,
            relativeTo: anchor,
            terminalHint: terminalHint
        ).standard_path
    }

    private static func resolveRelative(
        _ raw: String,
        baseURL: URL,
        terminalHint: PathTerminalHint
    ) -> ResolvedPathReference {
        let url = URL(
            fileURLWithPath: raw,
            relativeTo: baseURL
        ).standardizedFileURL

        return .init(
            url: url,
            terminalHint: terminalHint
        )
    }

    private static func inferredTerminalHint(
        from raw: String,
        explicit: PathTerminalHint
    ) -> PathTerminalHint {
        guard explicit == .unspecified else {
            return explicit
        }

        if raw == "~" || raw == "$HOME" || raw == "$CWD" || raw.hasSuffix("/") {
            return .directory
        }

        return .unspecified
    }
}

private extension String {
    func removingPrefix(
        _ prefix: String
    ) -> String? {
        guard hasPrefix(prefix) else {
            return nil
        }

        return String(dropFirst(prefix.count))
    }
}
