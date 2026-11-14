import Primitives

public struct PathTreeRenderOptions: Sendable, Codable, Equatable, Hashable {
    public var indentation: String
    public var includeRoot: Bool
    public var includeTrailingSlashForDirectories: Bool
    public var sortChildren: Bool
    /// Directories at this depth (0 for the root's children) show what
    /// they contain as counts, `Sources/ (3 dirs, 41 files)`, instead of
    /// listing it. Nil lists everything.
    public var collapseDepth: Int?

    public init(
        indentation: String = "    ",
        includeRoot: Bool = true,
        includeTrailingSlashForDirectories: Bool = true,
        sortChildren: Bool = false,
        collapseDepth: Int? = nil
    ) {
        self.indentation = indentation
        self.includeRoot = includeRoot
        self.includeTrailingSlashForDirectories = includeTrailingSlashForDirectories
        self.sortChildren = sortChildren
        self.collapseDepth = collapseDepth.map { max(0, $0) }
    }

    public init(
        indentSize: Int,
        includeRoot: Bool = true,
        includeTrailingSlashForDirectories: Bool = true,
        sortChildren: Bool = false,
        collapseDepth: Int? = nil
    ) {
        self.init(
            indentation: String(
                repeating: " ",
                count: max(0, indentSize)
            ),
            includeRoot: includeRoot,
            includeTrailingSlashForDirectories: includeTrailingSlashForDirectories,
            sortChildren: sortChildren,
            collapseDepth: collapseDepth
        )
    }
}

public extension PathTree {
    func render(
        _ options: PathTreeRenderOptions = .init()
    ) -> String {
        var lines: [String] = []

        let child_depth: Int

        if options.includeRoot {
            lines.append(
                renderedRootName(
                    options
                )
            )
            child_depth = 1
        } else {
            child_depth = 0
        }

        let root_order: TreeRootOrderPolicy<PathTreeValue>
        let child_order: TreeChildOrderPolicy<PathTreeValue>

        if options.sortChildren {
            root_order = .sorted_by_value { lhs, rhs in
                lhs.rendered_component
                    < rhs.rendered_component
            }

            child_order = .sorted_by_value { lhs, rhs in
                lhs.rendered_component
                    < rhs.rendered_component
            }
        } else {
            root_order = .natural
            child_order = .natural
        }

        for located in structure.walk(
            .depth_first_preorder,
            root_order: root_order,
            child_order: child_order
        ) {
            if let collapse = options.collapseDepth,
               located.address.depth > collapse {
                continue
            }

            let depth = child_depth
                + located.address.depth

            let prefix = String(
                repeating: options.indentation,
                count: max(
                    0,
                    depth
                )
            )

            var line = prefix
                + located.node.value.rendered_name(
                    trailing_slash_for_directories: options.includeTrailingSlashForDirectories
                )

            if located.address.depth == options.collapseDepth,
               !located.node.children.isEmpty {
                line += " " + PathTreeContentCount(
                    located.node
                ).rendered
            }

            lines.append(
                line
            )
        }

        return lines.joined(
            separator: "\n"
        )
    }

    func render(
        indentation: String = "    ",
        includeRoot: Bool = true,
        includeTrailingSlashForDirectories: Bool = true,
        sortChildren: Bool = false
    ) -> String {
        render(
            PathTreeRenderOptions(
                indentation: indentation,
                includeRoot: includeRoot,
                includeTrailingSlashForDirectories: includeTrailingSlashForDirectories,
                sortChildren: sortChildren
            )
        )
    }
}

public extension PathTreeNode {
    func render(
        _ options: PathTreeRenderOptions = .init()
    ) -> String {
        renderLines(
            depth: 0,
            options: options
        )
        .joined(separator: "\n")
    }

    func render(
        indentation: String = "    ",
        includeTrailingSlashForDirectories: Bool = true,
        sortChildren: Bool = false
    ) -> String {
        render(
            PathTreeRenderOptions(
                indentation: indentation,
                includeRoot: false,
                includeTrailingSlashForDirectories: includeTrailingSlashForDirectories,
                sortChildren: sortChildren
            )
        )
    }
}

extension PathTreeNode {
    func renderLines(
        depth: Int,
        options: PathTreeRenderOptions
    ) -> [String] {
        let prefix = String(
            repeating: options.indentation,
            count: max(0, depth)
        )

        let current = prefix + renderedName(
            trailingSlashForDirectories: options.includeTrailingSlashForDirectories
        )

        if depth == options.collapseDepth,
           !children.isEmpty {
            return [
                current + " " + PathTreeContentCount(
                    PathTreePrimitivesBridge.node(
                        self
                    )
                ).rendered
            ]
        }

        let child_lines = options.ordered(children).flatMap {
            $0.renderLines(
                depth: depth + 1,
                options: options
            )
        }

        return [current] + child_lines
    }
}

/// Directories and files below a collapsed directory.
struct PathTreeContentCount {
    var directories = 0
    var files = 0

    init(
        _ node: Tree<PathTreeValue>.Node
    ) {
        for child in node.children {
            if child.value.is_directory {
                directories += 1
            } else {
                files += 1
            }

            let nested = PathTreeContentCount(
                child
            )
            directories += nested.directories
            files += nested.files
        }
    }

    var rendered: String {
        "(\(directories) \(directories == 1 ? "dir" : "dirs"), \(files) \(files == 1 ? "file" : "files"))"
    }
}

private extension PathTree {
    func renderedRootName(
        _ options: PathTreeRenderOptions
    ) -> String {
        var name: String

        if root.isRoot {
            name = "/"
        } else if let basename = root.basename {
            name = basename
        } else {
            name = root.render(
                as: .relative,
                filetype: false
            )
        }

        if name.isEmpty {
            name = "."
        }

        guard options.includeTrailingSlashForDirectories,
              name != "/",
              !name.hasSuffix("/") else {
            return name
        }

        return name + "/"
    }
}

private extension PathTreeRenderOptions {
    func ordered(
        _ children: [PathTreeNode]
    ) -> [PathTreeNode] {
        guard sortChildren else {
            return children
        }

        return children.sorted {
            $0.renderedComponent < $1.renderedComponent
        }
    }
}
