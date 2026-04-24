import Foundation

public enum PathCreation {
    public static func directory(
        _ path: StandardPath,
        withIntermediateDirectories: Bool = true,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        try directory(
            at: path.directory_url,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: attributes
        )
    }

    public static func directory(
        at url: URL,
        withIntermediateDirectories: Bool = true,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        try FileManager.default.createDirectory(
            at: url.standardizedFileURL,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: attributes
        )
    }

    public static func directories(
        _ paths: [StandardPath],
        withIntermediateDirectories: Bool = true,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        for path in paths {
            try directory(
                path,
                withIntermediateDirectories: withIntermediateDirectories,
                attributes: attributes
            )
        }
    }

    public static func directories(
        at urls: [URL],
        withIntermediateDirectories: Bool = true,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        for url in urls {
            try directory(
                at: url,
                withIntermediateDirectories: withIntermediateDirectories,
                attributes: attributes
            )
        }
    }

    public static func parent(
        of path: StandardPath,
        withIntermediateDirectories: Bool = true,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        guard let parent = path.parent() else {
            return
        }

        try directory(
            parent,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: attributes
        )
    }

    public static func parent(
        of url: URL,
        withIntermediateDirectories: Bool = true,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        try directory(
            at: url.standardizedFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: attributes
        )
    }
}

public extension StandardPath {
    func createDirectory(
        withIntermediateDirectories: Bool = true,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        try PathCreation.directory(
            self,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: attributes
        )
    }

    func createParentDirectory(
        withIntermediateDirectories: Bool = true,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        try PathCreation.parent(
            of: self,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: attributes
        )
    }
}
