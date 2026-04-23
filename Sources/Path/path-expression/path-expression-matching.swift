import Foundation
import FileTypes

public extension PathExpression {
    func matches(
        path candidate: StandardPath,
        type: PathSegmentType,
        relativeTo anchor: PathAnchor = .cwd
    ) -> Bool {
        guard terminalHintMatches(type: type) else {
            return false
        }

        if pattern.isConcrete {
            return resolvedConcretePath(
                relativeTo: anchor
            ) == candidate
        }

        let rootPath = StandardPath(
            fileURL: scanRoot(relativeTo: anchor),
            terminalHint: .directory,
            inferFileType: false
        )

        guard let relative = candidate.relative(to: rootPath) else {
            return false
        }

        return scanPattern.matches(relative)
    }
}

private extension PathExpression {
    func resolvedConcretePath(
        relativeTo anchor: PathAnchor
    ) -> StandardPath {
        let baseURL = resolvedAnchor(
            relativeTo: anchor
        )
        .directory_url

        let basePath = StandardPath(
            fileURL: baseURL,
            terminalHint: .directory,
            inferFileType: false
        )

        var components = pattern.staticPrefixStrings
        var filetype: AnyFileType?

        if terminalHint != .directory,
           let last = components.last,
           let parsedType = try? AnyFileType(filename: last) {
            let stem = String(
                last.dropLast(parsedType.component.count)
            )

            if !stem.isEmpty {
                components[components.count - 1] = stem
                filetype = parsedType
            }
        }

        guard !components.isEmpty else {
            return basePath
        }

        return StandardPath(
            from: basePath,
            components,
            filetype: filetype
        )
    }

    func terminalHintMatches(
        type: PathSegmentType
    ) -> Bool {
        switch terminalHint {
        case .unspecified:
            return true

        case .file:
            return type == .file

        case .directory:
            return type == .directory
        }
    }
}
