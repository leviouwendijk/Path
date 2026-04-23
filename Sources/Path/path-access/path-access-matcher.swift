public enum PathAccessMatcher: Sendable, Codable, Equatable, Hashable {
    case component(String)
    case basename(String)
    case suffix(String)
    case expression(PathExpression)
}

public extension PathAccessMatcher {
    var summary: String {
        switch self {
        case .component(let value):
            return "component:\(value)"

        case .basename(let value):
            return "basename:\(value)"

        case .suffix(let value):
            return "suffix:\(value)"

        case .expression(let value):
            return "expression:\(value.pathAccessSummary)"
        }
    }

    func matches(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> Bool {
        switch self {
        case .component(let value):
            return path.relative.segments.contains {
                $0.value == value
            }

        case .basename(let value):
            return path.relative.basename == value

        case .suffix(let value):
            guard let basename = path.relative.basename else {
                return false
            }

            return basename.hasSuffix(value)

        case .expression(let expression):
            return expressionMatches(
                expression,
                path: path,
                type: type
            )
        }
    }
}

private extension PathAccessMatcher {
    func expressionMatches(
        _ expression: PathExpression,
        path: ScopedPath,
        type: PathSegmentType?
    ) -> Bool {
        let anchor = PathAnchor.directoryPath(path.root)

        if let type {
            return expression.matches(
                path: path.absolute,
                type: type,
                relativeTo: anchor
            )
        }

        return expression.matches(
            path: path.absolute,
            type: .file,
            relativeTo: anchor
        ) || expression.matches(
            path: path.absolute,
            type: .directory,
            relativeTo: anchor
        )
    }
}

private extension PathExpression {
    var pathAccessSummary: String {
        let renderedComponents = pattern.components.map {
            $0.pathAccessRendered
        }
        .joined(separator: "/")

        let anchorPrefix: String
        switch anchor {
        case .relative:
            anchorPrefix = ""

        case .root:
            anchorPrefix = "/"

        case .home:
            anchorPrefix = "~/"

        case .cwd:
            anchorPrefix = "$CWD/"
        }

        let body: String
        if renderedComponents.isEmpty {
            body = anchorPrefix
        } else {
            body = anchorPrefix + renderedComponents
        }

        switch terminalHint {
        case .directory:
            if body.isEmpty {
                return "./"
            }

            return body.hasSuffix("/") ? body : body + "/"

        case .file, .unspecified:
            return body.isEmpty ? "." : body
        }
    }
}

private extension PathPatternComponent {
    var pathAccessRendered: String {
        switch self {
        case .literal(let value):
            return value

        case .any:
            return "*"

        case .recursive:
            return "**"

        case .componentPattern(let value):
            return value
        }
    }
}
