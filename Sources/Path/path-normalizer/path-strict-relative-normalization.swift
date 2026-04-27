import FileTypes

public enum PathStrictRelativeNormalization {
    public static func path(
        rawPath: String,
        root: StandardPath,
        filetype: AnyFileType? = nil
    ) throws -> StandardPath {
        let trimmed = rawPath.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.hasPrefix("/") else {
            throw PathSandboxError.pathEscapesSandbox(
                path: StandardPath(
                    rawPath: rawPath,
                    filetype: filetype
                ),
                root: root
            )
        }

        let parts = trimmed
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)

        var normalized: [String] = []
        normalized.reserveCapacity(parts.count)

        for part in parts {
            switch part {
            case "", ".":
                continue

            case "..":
                guard !normalized.isEmpty else {
                    throw PathSandboxError.pathEscapesSandbox(
                        path: StandardPath(
                            rawPath: rawPath,
                            filetype: filetype
                        ),
                        root: root
                    )
                }

                normalized.removeLast()

            default:
                normalized.append(part)
            }
        }

        return StandardPath(
            normalized,
            filetype: filetype
        )
    }
}
