public enum PathNormalization {
    public static func root(
        _ path: StandardPath
    ) -> StandardPath {
        var normalized: [PathSegment] = []
        normalized.reserveCapacity(path.segments.count)

        for segment in path.segments {
            switch segment.value {
            case "", ".":
                continue

            case "..":
                if !normalized.isEmpty {
                    normalized.removeLast()
                }

            default:
                normalized.append(
                    PathSegment(
                        value: segment.value,
                        type: segment.type
                    )
                )
            }
        }

        return StandardPath(
            normalized,
            filetype: nil
        )
    }

    public static func relative(
        to root: StandardPath,
        _ path: StandardPath
    ) throws -> StandardPath {
        var normalized: [PathSegment] = []
        normalized.reserveCapacity(path.segments.count)

        for segment in path.segments {
            switch segment.value {
            case "", ".":
                continue

            case "..":
                guard !normalized.isEmpty else {
                    throw PathSandboxError.pathEscapesSandbox(
                        path: path,
                        root: root
                    )
                }

                normalized.removeLast()

            default:
                normalized.append(
                    PathSegment(
                        value: segment.value,
                        type: segment.type
                    )
                )
            }
        }

        return StandardPath(
            normalized,
            filetype: path.filetype
        )
    }
}
