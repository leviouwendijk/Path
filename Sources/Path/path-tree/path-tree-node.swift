import FileTypes

public struct PathTreeNode: Sendable, Codable, Equatable, Hashable {
    public var segment: PathSegment
    public var filetype: AnyFileType?
    public var children: [PathTreeNode]

    public init(
        segment: PathSegment,
        filetype: AnyFileType? = nil,
        children: [PathTreeNode] = []
    ) {
        Self.validate(segment)

        precondition(
            segment.type != .file || children.isEmpty,
            "File path tree nodes cannot contain children."
        )

        self.segment = segment
        self.filetype = filetype
        self.children = children
    }

    public init(
        _ value: String,
        type: PathSegmentType = .directory,
        filetype: AnyFileType? = nil,
        children: [PathTreeNode] = []
    ) {
        self.init(
            segment: PathSegment(
                value,
                type
            ),
            filetype: filetype,
            children: children
        )
    }

    public init(
        _ value: String,
        type: PathSegmentType = .directory,
        filetype: AnyFileType? = nil,
        @PathTreeBuilder children: () -> [PathTreeNode]
    ) {
        self.init(
            value,
            type: type,
            filetype: filetype,
            children: children()
        )
    }
}

public extension PathTreeNode {
    static func directory(
        _ value: String,
        children: [PathTreeNode] = []
    ) -> Self {
        Self(
            value,
            type: .directory,
            children: children
        )
    }

    static func directory(
        _ value: String,
        @PathTreeBuilder children: () -> [PathTreeNode]
    ) -> Self {
        Self.directory(
            value,
            children: children()
        )
    }

    static func file(
        _ value: String,
        filetype: AnyFileType? = nil
    ) -> Self {
        Self(
            value,
            type: .file,
            filetype: filetype
        )
    }

    static func component(
        _ value: String,
        type: PathSegmentType = .directory,
        filetype: AnyFileType? = nil,
        children: [PathTreeNode] = []
    ) -> Self {
        Self(
            value,
            type: type,
            filetype: filetype,
            children: children
        )
    }

    static func component(
        _ value: String,
        type: PathSegmentType = .directory,
        filetype: AnyFileType? = nil,
        @PathTreeBuilder children: () -> [PathTreeNode]
    ) -> Self {
        Self.component(
            value,
            type: type,
            filetype: filetype,
            children: children()
        )
    }
}

public extension PathTreeNode {
    var type: PathSegmentType {
        segment.type ?? .directory
    }

    var isDirectory: Bool {
        type == .directory
    }

    var isFile: Bool {
        type == .file
    }

    var renderedComponent: String {
        guard let filetype else {
            return segment.value
        }

        return segment.value + filetype.component
    }

    func renderedName(
        trailingSlashForDirectories: Bool = true
    ) -> String {
        guard isDirectory,
              trailingSlashForDirectories,
              !renderedComponent.hasSuffix("/") else {
            return renderedComponent
        }

        return renderedComponent + "/"
    }
}

public extension PathTreeNode {
    mutating func append(
        _ child: PathTreeNode,
        replacingExisting: Bool = false
    ) throws {
        guard isDirectory else {
            throw PathTreeModelError.destinationIsFile(
                StandardPath(
                    [segment],
                    filetype: filetype
                )
            )
        }

        try children.appendPathTreeNode(
            child,
            replacingExisting: replacingExisting
        )
    }

    func appending(
        _ child: PathTreeNode,
        replacingExisting: Bool = false
    ) throws -> PathTreeNode {
        var copy = self

        try copy.append(
            child,
            replacingExisting: replacingExisting
        )

        return copy
    }

    mutating func appendDirectory(
        _ path: StandardPath
    ) throws {
        try children.ensurePathTreePath(
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
        try children.ensurePathTreePath(
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
        let terminal_type = type
            ?? path.segments.last?.type
            ?? (path.filetype == nil ? .directory : .file)

        try children.ensurePathTreePath(
            path,
            terminalType: terminal_type
        )
    }

    mutating func rename(
        to newName: String
    ) {
        let replacement = PathSegment(
            newName,
            segment.type
        )

        Self.validate(replacement)
        segment = replacement
    }
}

public extension PathTreeNode {
    func contains(
        segment value: String
    ) -> Bool {
        segment.value == value || children.contains {
            $0.contains(segment: value)
        }
    }

    func contains(
        segment candidate: PathSegment
    ) -> Bool {
        segment == candidate || children.contains {
            $0.contains(segment: candidate)
        }
    }

    func flattenedPaths(
        relativeTo base: StandardPath = StandardPath()
    ) -> [StandardPath] {
        let current = StandardPath(
            from: base,
            [segment.value],
            filetype: filetype
        )

        let child_base = StandardPath(
            from: base,
            [segment.value]
        )

        return [current] + children.flatMap {
            $0.flattenedPaths(relativeTo: child_base)
        }
    }
}

extension Array where Element == PathTreeNode {
    func pathTreeNode(
        at relativePath: StandardPath
    ) -> PathTreeNode? {
        guard let first = relativePath.segments.first else {
            return nil
        }

        let terminal = relativePath.segments.count == 1

        guard let index = pathTreeIndex(
            matching: first,
            filetype: terminal ? relativePath.filetype : nil,
            matchFiletype: terminal
        ) else {
            return nil
        }

        if terminal {
            return self[index]
        }

        return self[index].children.pathTreeNode(
            at: relativePath.droppingFirstSegment()
        )
    }

    mutating func appendPathTreeNode(
        _ node: PathTreeNode,
        replacingExisting: Bool = false
    ) throws {
        if let index = firstIndex(where: { $0.hasSameIdentity(as: node) }) {
            guard replacingExisting else {
                throw PathTreeModelError.duplicateNode(
                    node.renderedComponent
                )
            }

            self[index] = node
            return
        }

        append(node)
    }

    mutating func insertPathTreeNode(
        _ node: PathTreeNode,
        under parent: StandardPath,
        replacingExisting: Bool = false
    ) throws {
        guard let first = parent.segments.first else {
            try appendPathTreeNode(
                node,
                replacingExisting: replacingExisting
            )
            return
        }

        let terminal = parent.segments.count == 1

        guard let index = pathTreeIndex(
            matching: first,
            filetype: terminal ? parent.filetype : nil,
            matchFiletype: terminal
        ) else {
            throw PathTreeModelError.destinationNotFound(parent)
        }

        guard self[index].isDirectory else {
            throw PathTreeModelError.destinationIsFile(parent)
        }

        if terminal {
            try self[index].append(
                node,
                replacingExisting: replacingExisting
            )
            return
        }

        try self[index].children.insertPathTreeNode(
            node,
            under: parent.droppingFirstSegment(),
            replacingExisting: replacingExisting
        )
    }

    mutating func removePathTreeNode(
        at relativePath: StandardPath
    ) throws -> PathTreeNode {
        guard let first = relativePath.segments.first else {
            throw PathTreeModelError.cannotMoveRoot
        }

        let terminal = relativePath.segments.count == 1

        guard let index = pathTreeIndex(
            matching: first,
            filetype: terminal ? relativePath.filetype : nil,
            matchFiletype: terminal
        ) else {
            throw PathTreeModelError.nodeNotFound(relativePath)
        }

        if terminal {
            return remove(at: index)
        }

        guard self[index].isDirectory else {
            throw PathTreeModelError.destinationIsFile(relativePath)
        }

        return try self[index].children.removePathTreeNode(
            at: relativePath.droppingFirstSegment()
        )
    }

    mutating func ensurePathTreePath(
        _ path: StandardPath,
        terminalType: PathSegmentType
    ) throws {
        guard let first = path.segments.first else {
            throw PathTreeModelError.emptyRelativePath
        }

        let terminal = path.segments.count == 1

        if let index = pathTreeIndex(
            matching: first,
            filetype: terminal ? path.filetype : nil,
            matchFiletype: terminal
        ) {
            if terminal {
                return
            }

            guard self[index].isDirectory else {
                throw PathTreeModelError.destinationIsFile(path)
            }

            try self[index].children.ensurePathTreePath(
                path.droppingFirstSegment(),
                terminalType: terminalType
            )
            return
        }

        if terminal {
            append(
                PathTreeNode(
                    segment: PathSegment(
                        first.value,
                        terminalType
                    ),
                    filetype: path.filetype
                )
            )
            return
        }

        var directory = PathTreeNode.directory(first.value)

        try directory.children.ensurePathTreePath(
            path.droppingFirstSegment(),
            terminalType: terminalType
        )

        append(directory)
    }

    func pathTreeIndex(
        matching segment: PathSegment,
        filetype: AnyFileType?,
        matchFiletype: Bool
    ) -> Index? {
        firstIndex {
            $0.segment.value == segment.value
                && (!matchFiletype || $0.filetype == filetype)
        }
    }
}

private extension PathTreeNode {
    func hasSameIdentity(
        as other: PathTreeNode
    ) -> Bool {
        segment.value == other.segment.value
            && filetype == other.filetype
    }

    static func validate(
        _ segment: PathSegment
    ) {
        precondition(
            !segment.value.isEmpty,
            "Path tree node segments cannot be empty."
        )

        precondition(
            !segment.value.contains("/"),
            "Path tree node segments must be atomic. Use appendPath(rawPath:) for slash-bearing input."
        )

        precondition(
            segment.value != ".",
            "Path tree node segments cannot be '.'."
        )

        precondition(
            segment.value != "..",
            "Path tree node segments cannot be '..'."
        )
    }
}

private extension StandardPath {
    func droppingFirstSegment() -> StandardPath {
        StandardPath(
            Array(segments.dropFirst()),
            filetype: filetype
        )
    }
}
