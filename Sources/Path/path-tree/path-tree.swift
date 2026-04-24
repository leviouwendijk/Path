import Foundation
import FileTypes

public struct PathTree: Sendable, Codable, Equatable, Hashable {
    public var root: StandardPath
    public var children: [PathTreeNode]

    public init(
        root: StandardPath,
        children: [PathTreeNode] = []
    ) {
        self.root = PathNormalization.root(root)
        self.children = children
    }

    public init(
        root: StandardPath,
        @PathTreeBuilder children: () -> [PathTreeNode]
    ) {
        self.init(
            root: root,
            children: children()
        )
    }
}

public extension PathTree {
    func descends(
        _ candidate: StandardPath
    ) -> Bool {
        PathNormalization.path(candidate)
            .descends(from: root)
    }

    func relative(
        _ candidate: StandardPath
    ) -> StandardPath? {
        PathNormalization.path(candidate)
            .relative(to: root)
    }

    func require_relative(
        _ candidate: StandardPath
    ) throws -> StandardPath {
        guard let relative = relative(candidate) else {
            throw PathSandboxError.pathEscapesSandbox(
                path: candidate,
                root: root
            )
        }

        return relative
    }

    func contains(
        segment: String
    ) -> Bool {
        root.segments.contains {
            $0.value == segment
        } || children.contains {
            $0.contains(segment: segment)
        }
    }

    func contains(
        segment: PathSegment
    ) -> Bool {
        root.segments.contains(segment) || children.contains {
            $0.contains(segment: segment)
        }
    }

    func appending(
        _ relative: StandardPath
    ) throws -> StandardPath {
        let normalized_relative = try PathNormalization.relative(
            to: root,
            relative
        )

        return StandardPath(
            from: root,
            normalized_relative.segments.map(\.value),
            filetype: normalized_relative.filetype
        )
    }
}

public extension PathTree {
    var modelPaths: [StandardPath] {
        children.flatMap {
            $0.flattenedPaths(relativeTo: root)
        }
    }

    func node(
        at path: StandardPath
    ) -> PathTreeNode? {
        let relative_path = modelRelative(path)

        guard !relative_path.segments.isEmpty else {
            return nil
        }

        return children.pathTreeNode(at: relative_path)
    }

    func contains(
        path: StandardPath
    ) -> Bool {
        let relative_path = modelRelative(path)

        guard !relative_path.segments.isEmpty else {
            return true
        }

        return children.pathTreeNode(at: relative_path) != nil
    }
}

public extension PathTree {
    mutating func append(
        _ node: PathTreeNode,
        replacingExisting: Bool = false
    ) throws {
        try children.insertPathTreeNode(
            node,
            under: StandardPath(),
            replacingExisting: replacingExisting
        )
    }

    mutating func append(
        _ nodes: [PathTreeNode],
        replacingExisting: Bool = false
    ) throws {
        for node in nodes {
            try append(
                node,
                replacingExisting: replacingExisting
            )
        }
    }

    mutating func append(
        _ node: PathTreeNode,
        under parent: StandardPath,
        replacingExisting: Bool = false
    ) throws {
        try children.insertPathTreeNode(
            node,
            under: modelRelative(parent),
            replacingExisting: replacingExisting
        )
    }

    mutating func append(
        _ nodes: [PathTreeNode],
        under parent: StandardPath,
        replacingExisting: Bool = false
    ) throws {
        for node in nodes {
            try append(
                node,
                under: parent,
                replacingExisting: replacingExisting
            )
        }
    }

    mutating func appendDirectory(
        _ path: StandardPath
    ) throws {
        try ensureModelPath(
            path,
            terminalType: .directory
        )
    }

    mutating func appendDirectory(
        rawPath: String
    ) throws {
        try appendDirectory(
            StandardPath(rawPath: rawPath)
        )
    }

    mutating func appendFile(
        _ path: StandardPath
    ) throws {
        try ensureModelPath(
            path,
            terminalType: .file
        )
    }

    mutating func appendFile(
        rawPath: String,
        filetype: AnyFileType? = nil
    ) throws {
        try appendFile(
            StandardPath(
                rawPath: rawPath,
                filetype: filetype
            )
        )
    }

    mutating func appendPath(
        _ path: StandardPath,
        type: PathSegmentType? = nil
    ) throws {
        let relative_path = modelRelative(path)

        let terminal_type = type
            ?? relative_path.segments.last?.type
            ?? (relative_path.filetype == nil ? .directory : .file)

        try ensureRelativeModelPath(
            relative_path,
            terminalType: terminal_type
        )
    }

    mutating func appendPath(
        rawPath: String,
        type: PathSegmentType? = nil,
        filetype: AnyFileType? = nil
    ) throws {
        try appendPath(
            StandardPath(
                rawPath: rawPath,
                filetype: filetype
            ),
            type: type
        )
    }

    mutating func move(
        _ source: StandardPath,
        under destination: StandardPath,
        replacingExisting: Bool = false
    ) throws {
        let source_relative = modelRelative(source)
        let destination_relative = modelRelative(destination)

        guard !source_relative.segments.isEmpty else {
            throw PathTreeModelError.cannotMoveRoot
        }

        if !destination_relative.segments.isEmpty,
           destination_relative.descends(from: source_relative) {
            throw PathTreeModelError.cannotMoveNodeIntoItself(
                source_relative,
                destination_relative
            )
        }

        var copy = self
        let node = try copy.children.removePathTreeNode(
            at: source_relative
        )

        try copy.children.insertPathTreeNode(
            node,
            under: destination_relative,
            replacingExisting: replacingExisting
        )

        self = copy
    }

    mutating func rename(
        _ path: StandardPath,
        to newName: String
    ) throws {
        let relative_path = modelRelative(path)

        guard !relative_path.segments.isEmpty else {
            throw PathTreeModelError.cannotMoveRoot
        }

        let parent = StandardPath(
            Array(relative_path.segments.dropLast())
        )

        var copy = self
        var node = try copy.children.removePathTreeNode(
            at: relative_path
        )

        node.rename(to: newName)

        try copy.children.insertPathTreeNode(
            node,
            under: parent,
            replacingExisting: false
        )

        self = copy
    }
}

public extension PathTree {
    static func descends(
        from root: StandardPath,
        _ candidate: StandardPath
    ) -> Bool {
        PathTree(root: root)
            .descends(candidate)
    }

    static func relative(
        from root: StandardPath,
        _ candidate: StandardPath
    ) -> StandardPath? {
        PathTree(root: root)
            .relative(candidate)
    }
}

private extension PathTree {
    func modelRelative(
        _ path: StandardPath
    ) -> StandardPath {
        if let relative_path = relative(path) {
            return relative_path
        }

        return PathNormalization.path(path)
    }

    mutating func ensureModelPath(
        _ path: StandardPath,
        terminalType: PathSegmentType
    ) throws {
        try ensureRelativeModelPath(
            modelRelative(path),
            terminalType: terminalType
        )
    }

    mutating func ensureRelativeModelPath(
        _ relative_path: StandardPath,
        terminalType: PathSegmentType
    ) throws {
        guard !relative_path.segments.isEmpty else {
            throw PathTreeModelError.emptyRelativePath
        }

        try children.ensurePathTreePath(
            relative_path,
            terminalType: terminalType
        )
    }
}
