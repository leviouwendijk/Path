import Difference
import FileTypes
import Primitives

/// Semantic path information retained on both sides of a structural difference.
/// The ID can be a stable external object identity; the path can change.
public struct PathTreeDifferenceValue: Sendable, Codable, Hashable {
    public let identity: String
    public let path: StandardPath
    public let kind: PathSegmentType
    public let filetype: AnyFileType?

    public init(
        identity: String,
        path: StandardPath,
        kind: PathSegmentType,
        filetype: AnyFileType?
    ) {
        self.identity = identity
        self.path = path
        self.kind = kind
        self.filetype = filetype
    }
}

public enum PathTreeDifferenceError: Error, Sendable, Equatable {
    case mismatched_roots
}

public extension PathTree {
    /// Compares complete, same-root models. No filesystem scan is performed.
    /// Default identity is the full semantic path, so renames are remove/add.
    /// Supply stable identities for both versions to recognize actual moves.
    static func difference(
        before: PathTree,
        after: PathTree,
        source: TreeDifferenceSource = .observed,
        identity: ((StandardPath) -> String)? = nil
    ) throws -> TreeDifference<PathTreeDifferenceValue> {
        guard before.root == after.root else {
            throw PathTreeDifferenceError.mismatched_roots
        }
        let before_tree = before.difference_values(identity: identity)
        let after_tree = after.difference_values(identity: identity)
        return try TreeDiffer.make(
            before: before_tree,
            after: after_tree,
            source: source,
            identity: \.identity,
            label: { value in
                let last = value.path.render(
                    as: .relative, filetype: true
                ).split(separator: "/").last.map(String.init) ?? ""
                return value.kind == .directory ? last + "/" : last
            },
            equivalent: { old, new in
                old.kind == new.kind && old.filetype == new.filetype
            },
            relocated: { old, new in
                old.path != new.path
            }
        )
    }
}

private extension PathTree {
    func difference_values(
        identity: ((StandardPath) -> String)?
    ) -> Tree<PathTreeDifferenceValue> {
        func nodes(
            _ siblings: [Tree<PathTreeValue>.Node],
            parent: [String]
        ) -> [Tree<PathTreeDifferenceValue>.Node] {
            siblings.map { node in
                let components = parent + [node.value.segment.value]
                let path = StandardPath(
                    from: root,
                    components,
                    filetype: node.value.filetype
                )
                let semantic_id = identity?(path) ?? path.render(
                    as: .relative,
                    filetype: true
                )
                return .init(
                    .init(
                        identity: semantic_id,
                        path: path,
                        kind: node.value.type,
                        filetype: node.value.filetype
                    ),
                    children: nodes(node.children, parent: components)
                )
            }
        }
        return .init(roots: nodes(primitive_tree.roots, parent: []))
    }
}
