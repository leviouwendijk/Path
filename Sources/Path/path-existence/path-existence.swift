import Foundation

public struct PathExistence: Sendable {
    public static func check(
        url: URL
    ) -> (exists: Bool, type: PathSegmentType?) {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: url.standardizedFileURL.path,
            isDirectory: &isDirectory
        )
        let type = exists ? PathSegmentType.from(isDirectory) : nil

        return (
            exists: exists,
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
