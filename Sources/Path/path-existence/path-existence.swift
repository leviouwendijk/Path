import Foundation

public struct PathExistence: Sendable {
    public static func check(url: URL) -> (Bool, ProjectPathSegmentType?) {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        let type = exists ? ProjectPathSegmentType.from(isDirectory) : nil

        return (exists, type)
    }

    public static func readable(result: (Bool, ProjectPathSegmentType?)) -> String {
        var resp = ""
        if result.0 {
            if let type = result.1 {
                resp = "This \(type.rawValue) exists"
            } else {
                resp = "This path exists"
            }
        } else {
            resp = "This path does not exist"
        }
        return resp
    }
}
