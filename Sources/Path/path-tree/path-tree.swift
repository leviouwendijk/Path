import Foundation
import FileTypes
import Primitives

public struct PathTree: Sendable, Codable, Equatable, Hashable {
    public var root: StandardPath

    var structure: Tree<PathTreeValue>

    public var children: [PathTreeNode] {
        get {
            PathTreePrimitivesBridge.nodes(
                structure.roots
            )
        }
        set {
            structure = PathTreePrimitivesBridge.tree(
                newValue
            )
        }
    }

    public init(
        root: StandardPath,
        children: [PathTreeNode] = []
    ) {
        self.root = PathNormalization.root(
            root
        )
        self.structure = PathTreePrimitivesBridge.tree(
            children
        )
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

extension PathTree {
    private enum CodingKeys: String, CodingKey {
        case root
        case children
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let root = try container.decode(
            StandardPath.self,
            forKey: .root
        )

        let children = try container.decode(
            [PathTreeNode].self,
            forKey: .children
        )

        self.init(
            root: root,
            children: children
        )
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            root,
            forKey: .root
        )

        try container.encode(
            children,
            forKey: .children
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
        } || structure.walk().contains { located in
            located.node.value.segment.value == segment
        }
    }

    func contains(
        segment: PathSegment
    ) -> Bool {
        root.segments.contains(
            segment
        ) || structure.walk().contains { located in
            located.node.value.segment == segment
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
        structure.walk().compactMap { located in
            semantic_path(
                at: located.address
            )
        }
    }

    func node(
        at path: StandardPath
    ) -> PathTreeNode? {
        guard let address = tree_address(
            for: path
        ),
        let node = structure.node(
            at: address
        ) else {
            return nil
        }

        return PathTreePrimitivesBridge.node(
            node
        )
    }

    func contains(
        path: StandardPath
    ) -> Bool {
        let relative_path = modelRelative(
            path
        )

        guard !relative_path.segments.isEmpty else {
            return true
        }

        return tree_address(
            for: path
        ) != nil
    }
}

public extension PathTree {
    mutating func append(
        _ node: PathTreeNode,
        replacingExisting: Bool = false
    ) throws {
        try insert_tree_node(
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
        try insert_tree_node(
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
        let source_relative = modelRelative(
            source
        )
        let destination_relative = modelRelative(
            destination
        )

        guard !source_relative.segments.isEmpty else {
            throw PathTreeModelError.cannotMoveRoot
        }

        if !destination_relative.segments.isEmpty,
           destination_relative.descends(
                from: source_relative
           ) {
            throw PathTreeModelError.cannotMoveNodeIntoItself(
                source_relative,
                destination_relative
            )
        }

        var copy = self

        guard let source_address = copy.tree_address(
            for: source_relative
        ) else {
            throw PathTreeModelError.nodeNotFound(
                source_relative
            )
        }

        let node = try copy.structure.remove(
            at: source_address
        )

        try copy.insert_tree_node(
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
        let relative_path = modelRelative(
            path
        )

        guard !relative_path.segments.isEmpty else {
            throw PathTreeModelError.cannotMoveRoot
        }

        let parent = StandardPath(
            Array(
                relative_path.segments.dropLast()
            )
        )

        var copy = self

        guard let address = copy.tree_address(
            for: relative_path
        ) else {
            throw PathTreeModelError.nodeNotFound(
                relative_path
            )
        }

        var node = try copy.structure.remove(
            at: address
        )

        let validated = PathTreeNode(
            segment: PathSegment(
                newName,
                node.value.segment.type
            )
        )

        node.value.segment = validated.segment

        try copy.insert_tree_node(
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

    mutating func insert_tree_node(
        _ node: PathTreeNode,
        under parent: StandardPath,
        replacingExisting: Bool
    ) throws {
        try insert_tree_node(
            PathTreePrimitivesBridge.node(
                node
            ),
            under: parent,
            replacingExisting: replacingExisting
        )
    }

    mutating func insert_tree_node(
        _ replacement: Tree<PathTreeValue>.Node,
        under parent: StandardPath,
        replacingExisting: Bool
    ) throws {
        var copy = self

        if parent.segments.isEmpty {
            if let index = copy.structure.roots.firstIndex(
                where: { sibling in
                    sibling.value.segment.value
                        == replacement.value.segment.value
                        && sibling.value.filetype
                            == replacement.value.filetype
                }
            ) {
                guard replacingExisting else {
                    throw PathTreeModelError.duplicateNode(
                        replacement.value.rendered_component
                    )
                }

                let address = try TreeAddress(
                    root: index
                )

                try copy.structure.replace(
                    at: address,
                    with: replacement
                )
            } else {
                try copy.structure.insert_root(
                    replacement
                )
            }

            self = copy
            return
        }

        guard let parent_address = copy.tree_address(
            for: parent
        ),
        let parent_node = copy.structure.node(
            at: parent_address
        ) else {
            throw PathTreeModelError.destinationNotFound(
                parent
            )
        }

        guard parent_node.value.is_directory else {
            throw PathTreeModelError.destinationIsFile(
                parent
            )
        }

        if let index = parent_node.children.firstIndex(
            where: { sibling in
                sibling.value.segment.value
                    == replacement.value.segment.value
                    && sibling.value.filetype
                        == replacement.value.filetype
            }
        ) {
            guard replacingExisting else {
                throw PathTreeModelError.duplicateNode(
                    replacement.value.rendered_component
                )
            }

            let address = try parent_address.child(
                index
            )

            try copy.structure.replace(
                at: address,
                with: replacement
            )
        } else {
            try copy.structure.insert(
                replacement,
                under: parent_address
            )
        }

        self = copy
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

        var copy = self
        var parent_address: TreeAddress?

        for offset in relative_path.segments.indices {
            let segment = relative_path.segments[offset]
            let terminal = offset == relative_path.segments.index(
                before: relative_path.segments.endIndex
            )

            let siblings: [Tree<PathTreeValue>.Node]

            if let parent_address {
                guard let parent_node = copy.structure.node(
                    at: parent_address
                ) else {
                    throw PathTreeModelError.destinationNotFound(
                        relative_path
                    )
                }

                guard parent_node.value.is_directory else {
                    throw PathTreeModelError.destinationIsFile(
                        relative_path
                    )
                }

                siblings = parent_node.children
            } else {
                siblings = copy.structure.roots
            }

            if let index = siblings.firstIndex(
                where: { node in
                    node.value.segment.value == segment.value
                        && (!terminal
                            || node.value.filetype
                                == relative_path.filetype)
                }
            ) {
                let address: TreeAddress

                if let parent_address {
                    address = try parent_address.child(
                        index
                    )
                } else {
                    address = try TreeAddress(
                        root: index
                    )
                }

                if terminal {
                    self = copy
                    return
                }

                guard siblings[index].value.is_directory else {
                    throw PathTreeModelError.destinationIsFile(
                        relative_path
                    )
                }

                parent_address = address
                continue
            }

            let value = PathTreeValue(
                segment: PathSegment(
                    segment.value,
                    terminal
                        ? terminalType
                        : .directory
                ),
                filetype: terminal
                    ? relative_path.filetype
                    : nil
            )

            let inserted = Tree<PathTreeValue>.Node(
                value
            )

            let index = siblings.count
            let address: TreeAddress

            if let parent_address {
                try copy.structure.insert(
                    inserted,
                    under: parent_address
                )

                address = try parent_address.child(
                    index
                )
            } else {
                try copy.structure.insert_root(
                    inserted
                )

                address = try TreeAddress(
                    root: index
                )
            }

            parent_address = address
        }

        self = copy
    }
}
