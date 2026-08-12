import Foundation
import IO

public struct PathExistence: Sendable {
    public static func check(
        url: URL
    ) -> (exists: Bool, type: PathSegmentType?) {
        let fileSystem = FileSystem.default

        guard fileSystem.exists(
            url
        ) else {
            return (
                exists: false,
                type: nil
            )
        }

        let resolvedURL = fileSystem.resolve(
            url
        )

        let type: PathSegmentType?

        if
            let metadata = try? FileInspector(
                resolvedURL
            ).inspect(),
            let kind = metadata.kind
        {
            type = PathSegmentType(
                kind
            )
        } else {
            type = nil
        }

        return (
            exists: true,
            type: type
        )
    }

    public static func exists(
        url: URL
    ) -> Bool {
        check(
            url: url
        ).exists
    }

    public static func isDirectory(
        url: URL
    ) -> Bool {
        check(
            url: url
        ).type == .directory
    }

    public static func isFile(
        url: URL
    ) -> Bool {
        check(
            url: url
        ).type == .file
    }

    public static func readable(
        result: (exists: Bool, type: PathSegmentType?)
    ) -> String {
        if result.exists {
            if let type = result.type {
                return "This \(type.rawValue) exists"
            }

            return "This path exists"
        }

        return "This path does not exist"
    }
}
