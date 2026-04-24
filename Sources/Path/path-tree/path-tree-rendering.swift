public struct PathTreeRenderOptions: Sendable, Codable, Equatable, Hashable {
    public var indentation: String
    public var includeRoot: Bool
    public var includeTrailingSlashForDirectories: Bool
    public var sortChildren: Bool

    public init(
        indentation: String = "    ",
        includeRoot: Bool = true,
        includeTrailingSlashForDirectories: Bool = true,
        sortChildren: Bool = false
    ) {
        self.indentation = indentation
        self.includeRoot = includeRoot
        self.includeTrailingSlashForDirectories = includeTrailingSlashForDirectories
        self.sortChildren = sortChildren
    }

    public init(
        indentSize: Int,
        includeRoot: Bool = true,
        includeTrailingSlashForDirectories: Bool = true,
        sortChildren: Bool = false
    ) {
        self.init(
            indentation: String(
                repeating: " ",
                count: max(0, indentSize)
            ),
            includeRoot: includeRoot,
            includeTrailingSlashForDirectories: includeTrailingSlashForDirectories,
            sortChildren: sortChildren
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
                renderedRootName(options)
            )
            child_depth = 1
        } else {
            child_depth = 0
        }

        for child in options.ordered(children) {
            lines.append(
                contentsOf: child.renderLines(
                    depth: child_depth,
                    options: options
                )
            )
        }

        return lines.joined(separator: "\n")
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

        let child_lines = options.ordered(children).flatMap {
            $0.renderLines(
                depth: depth + 1,
                options: options
            )
        }

        return [current] + child_lines
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
