import FileTypes
import Primitives

package struct PathTreeValue:
    Sendable,
    Codable,
    Equatable,
    Hashable
{
    package var segment: PathSegment
    package var filetype: AnyFileType?

    package init(
        segment: PathSegment,
        filetype: AnyFileType? = nil
    ) {
        self.segment = segment
        self.filetype = filetype
    }
}

package extension PathTreeValue {
    var type: PathSegmentType {
        segment.type
            ?? .directory
    }

    var is_directory: Bool {
        type == .directory
    }

    var is_file: Bool {
        type == .file
    }

    var rendered_component: String {
        guard let filetype else {
            return segment.value
        }

        return segment.value
            + filetype.component
    }

    func rendered_name(
        trailing_slash_for_directories: Bool = true
    ) -> String {
        guard is_directory,
              trailing_slash_for_directories,
              !rendered_component.hasSuffix("/") else {
            return rendered_component
        }

        return rendered_component + "/"
    }
}

package extension PathTree {
    var primitive_tree: Tree<PathTreeValue> {
        structure
    }

    func tree_address(
        for path: StandardPath
    ) -> TreeAddress? {
        let relative_path: StandardPath

        if let relative = relative(
            path
        ) {
            relative_path = relative
        } else {
            relative_path = PathNormalization.path(
                path
            )
        }

        guard !relative_path.segments.isEmpty else {
            return nil
        }

        var siblings = structure.roots
        var selected_root: Int?
        var descendants: [Int] = []

        for offset in relative_path.segments.indices {
            let segment = relative_path.segments[offset]
            let terminal = offset == relative_path.segments.index(
                before: relative_path.segments.endIndex
            )

            guard let index = siblings.firstIndex(
                where: { node in
                    node.value.segment.value == segment.value
                        && (!terminal || node.value.filetype == relative_path.filetype)
                }
            ) else {
                return nil
            }

            if selected_root == nil {
                selected_root = index
            } else {
                descendants.append(
                    index
                )
            }

            if !terminal {
                siblings = siblings[index].children
            }
        }

        guard let selected_root else {
            return nil
        }

        return try? TreeAddress(
            root: selected_root,
            descendants: descendants
        )
    }

    func semantic_path(
        at address: TreeAddress
    ) -> StandardPath? {
        guard structure.roots.indices.contains(
            address.root
        ) else {
            return nil
        }

        var node = structure.roots[address.root]
        var values: [PathTreeValue] = [
            node.value,
        ]

        for child_index in address.descendants {
            guard node.children.indices.contains(
                child_index
            ) else {
                return nil
            }

            node = node.children[child_index]
            values.append(
                node.value
            )
        }

        guard let terminal = values.last else {
            return nil
        }

        return StandardPath(
            from: root,
            values.map { value in
                value.segment.value
            },
            filetype: terminal.filetype
        )
    }
}

enum PathTreePrimitivesBridge {
    static func tree(
        _ source: [PathTreeNode]
    ) -> Tree<PathTreeValue> {
        .init(
            roots: source.map { node in
                self.node(
                    node
                )
            }
        )
    }

    static func node(
        _ source: PathTreeNode
    ) -> Tree<PathTreeValue>.Node {
        .init(
            .init(
                segment: source.segment,
                filetype: source.filetype
            ),
            children: source.children.map { child in
                node(
                    child
                )
            }
        )
    }

    static func nodes(
        _ source: [Tree<PathTreeValue>.Node]
    ) -> [PathTreeNode] {
        source.map { node in
            self.node(
                node
            )
        }
    }

    static func node(
        _ source: Tree<PathTreeValue>.Node
    ) -> PathTreeNode {
        .init(
            segment: source.value.segment,
            filetype: source.value.filetype,
            children: source.children.map { child in
                node(
                    child
                )
            }
        )
    }
}
