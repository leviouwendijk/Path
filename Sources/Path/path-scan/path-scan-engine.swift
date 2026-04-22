import Foundation

public enum PathScanWarning: Sendable, Codable, Equatable {
    case duplicateInclude(PathExpression)
    case duplicateExclude(PathExpression)
    case includeShadowedByExclude(
        include: PathExpression,
        exclude: PathExpression
    )
    case selectionShadowedByExclude(
        selection: PathSelectionExpression,
        exclude: PathExpression
    )
}

public struct PathTraversalPlan: Sendable, Codable, Equatable {
    public let root: URL
    public let anchorDirectory: URL
    public let includes: [PathExpression]
    public let excludes: [PathExpression]
    public let selections: [PathSelectionExpression]

    public init(
        root: URL,
        anchorDirectory: URL,
        includes: [PathExpression],
        excludes: [PathExpression],
        selections: [PathSelectionExpression]
    ) {
        self.root = root.standardizedFileURL
        self.anchorDirectory = anchorDirectory.standardizedFileURL
        self.includes = includes
        self.excludes = excludes
        self.selections = selections
    }
}

public struct CompiledPathScanPlan: Sendable, Codable, Equatable {
    public let traversals: [PathTraversalPlan]
    public let warnings: [PathScanWarning]

    public init(
        traversals: [PathTraversalPlan],
        warnings: [PathScanWarning] = []
    ) {
        self.traversals = traversals
        self.warnings = warnings
    }
}

public struct PathScanMatch: Sendable, Codable, Equatable {
    public let url: URL
    public let path: StandardPath
    public let contentSelections: [ContentSelection]

    public init(
        url: URL,
        path: StandardPath,
        contentSelections: [ContentSelection] = []
    ) {
        self.url = url.standardizedFileURL
        self.path = path
        self.contentSelections = contentSelections
    }
}

public struct PathScanResult: Sendable, Codable, Equatable {
    public let matches: [PathScanMatch]
    public let warnings: [PathScanWarning]

    public init(
        matches: [PathScanMatch],
        warnings: [PathScanWarning] = []
    ) {
        self.matches = matches
        self.warnings = warnings
    }
}

public enum PathScanCompiler {
    public static func compile(
        _ specification: PathScanSpecification,
        relativeTo anchor: PathAnchor = .cwd
    ) -> CompiledPathScanPlan {
        let warnings = analyze(specification)
        let anchorDirectory = anchor.directory_url.standardizedFileURL

        var buckets: [URL: TraversalBuilder] = [:]

        for include in specification.includes {
            let root = include.scanRoot(relativeTo: anchor)

            if buckets[root] == nil {
                buckets[root] = TraversalBuilder(root: root)
            }

            buckets[root]?.includes.append(include)
        }

        for selection in specification.selections {
            let root = selection.path.scanRoot(relativeTo: anchor)

            if buckets[root] == nil {
                buckets[root] = TraversalBuilder(root: root)
            }

            buckets[root]?.selections.append(selection)
        }

        let traversals = buckets.values
            .map {
                PathTraversalPlan(
                    root: $0.root,
                    anchorDirectory: anchorDirectory,
                    includes: $0.includes,
                    excludes: specification.excludes,
                    selections: $0.selections
                )
            }
            .sorted { $0.root.path < $1.root.path }

        return CompiledPathScanPlan(
            traversals: traversals,
            warnings: warnings
        )
    }
}

public enum PathScanner {
    public static func scan(
        _ plan: CompiledPathScanPlan,
        configuration: PathWalkConfiguration = .init()
    ) throws -> PathScanResult {
        var collected: [URL: PathScanMatch] = [:]

        for traversal in plan.traversals {
            let walker = PathWalker(
                root: traversal.root,
                configuration: configuration
            )

            for entry in try walker.walk() {
                if isExcluded(
                    entry,
                    excludes: traversal.excludes,
                    anchorDirectory: traversal.anchorDirectory
                ) {
                    continue
                }

                let matchedInclude = traversal.includes.contains {
                    matches(
                        entry: entry,
                        expression: $0,
                        root: traversal.root,
                        anchorDirectory: traversal.anchorDirectory
                    )
                }

                let matchedSelections = traversal.selections.compactMap {
                    selection -> ContentSelection? in
                    guard matches(
                        entry: entry,
                        expression: selection.path,
                        root: traversal.root,
                        anchorDirectory: traversal.anchorDirectory
                    ) else {
                        return nil
                    }

                    return selection.content
                }

                guard matchedInclude || !matchedSelections.isEmpty else {
                    continue
                }

                var existing = collected[entry.url] ?? PathScanMatch(
                    url: entry.url,
                    path: entry.absolutePath,
                    contentSelections: []
                )

                for selection in matchedSelections {
                    if !existing.contentSelections.contains(where: { $0 == selection }) {
                        existing = PathScanMatch(
                            url: existing.url,
                            path: existing.path,
                            contentSelections: existing.contentSelections + [selection]
                        )
                    }
                }

                collected[entry.url] = existing
            }
        }

        return PathScanResult(
            matches: collected.values.sorted { $0.url.path < $1.url.path },
            warnings: plan.warnings
        )
    }
}

private extension PathScanCompiler {
    struct TraversalBuilder {
        let root: URL
        var includes: [PathExpression] = []
        var selections: [PathSelectionExpression] = []
    }

    static func analyze(
        _ specification: PathScanSpecification
    ) -> [PathScanWarning] {
        var warnings: [PathScanWarning] = []

        warnings.append(contentsOf: duplicateIncludeWarnings(specification.includes))
        warnings.append(contentsOf: duplicateExcludeWarnings(specification.excludes))

        for include in specification.includes {
            for exclude in specification.excludes where include == exclude {
                warnings.append(
                    .includeShadowedByExclude(
                        include: include,
                        exclude: exclude
                    )
                )
            }
        }

        for selection in specification.selections {
            for exclude in specification.excludes where selection.path == exclude {
                warnings.append(
                    .selectionShadowedByExclude(
                        selection: selection,
                        exclude: exclude
                    )
                )
            }
        }

        return warnings
    }

    static func duplicateIncludeWarnings(
        _ includes: [PathExpression]
    ) -> [PathScanWarning] {
        var warnings: [PathScanWarning] = []

        for index in includes.indices {
            let lhs = includes[index]

            for rhs in includes.dropFirst(index + 1) where lhs == rhs {
                warnings.append(.duplicateInclude(rhs))
            }
        }

        return warnings
    }

    static func duplicateExcludeWarnings(
        _ excludes: [PathExpression]
    ) -> [PathScanWarning] {
        var warnings: [PathScanWarning] = []

        for index in excludes.indices {
            let lhs = excludes[index]

            for rhs in excludes.dropFirst(index + 1) where lhs == rhs {
                warnings.append(.duplicateExclude(rhs))
            }
        }

        return warnings
    }
}

private extension PathScanner {
    static func isExcluded(
        _ entry: PathWalkEntry,
        excludes: [PathExpression],
        anchorDirectory: URL
    ) -> Bool {
        excludes.contains { exclude in
            matchesConcrete(
                entry: entry,
                expression: exclude,
                anchorDirectory: anchorDirectory
            ) || matchesPattern(
                entry: entry,
                expression: exclude,
                root: exclude.scanRoot(
                    relativeTo: .directoryURL(anchorDirectory)
                )
            )
        }
    }

    static func matches(
        entry: PathWalkEntry,
        expression: PathExpression,
        root: URL,
        anchorDirectory: URL
    ) -> Bool {
        matchesConcrete(
            entry: entry,
            expression: expression,
            anchorDirectory: anchorDirectory
        ) || matchesPattern(
            entry: entry,
            expression: expression,
            root: root
        )
    }

    static func matchesConcrete(
        entry: PathWalkEntry,
        expression: PathExpression,
        anchorDirectory: URL
    ) -> Bool {
        guard let concreteURL = concreteURL(
            for: expression,
            relativeTo: anchorDirectory
        ) else {
            return false
        }

        guard terminalHintMatches(
            expression.terminalHint,
            type: entry.type
        ) else {
            return false
        }

        return concreteURL == entry.url
    }

    static func matchesPattern(
        entry: PathWalkEntry,
        expression: PathExpression,
        root: URL
    ) -> Bool {
        guard !expression.pattern.isConcrete else {
            return false
        }

        guard terminalHintMatches(
            expression.terminalHint,
            type: entry.type
        ) else {
            return false
        }

        guard let relativePath = relativePathIfDescendant(
            entry,
            under: root
        ) else {
            return false
        }

        return expression.scanPattern.matches(relativePath)
    }

    static func concreteURL(
        for expression: PathExpression,
        relativeTo anchorDirectory: URL
    ) -> URL? {
        guard expression.pattern.isConcrete else {
            return nil
        }

        let baseURL = expression.anchor
            .resolved(relativeTo: .directoryURL(anchorDirectory))
            .directory_url

        var components = expression.pattern.staticPrefixStrings
        var filetype: AnyFileType?

        if expression.terminalHint != .directory,
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

        if components.isEmpty {
            return baseURL.standardizedFileURL
        }

        return StandardPath(
            components,
            filetype: filetype
        )
        .url(
            base: baseURL,
            filetype: expression.terminalHint != .directory
        )
        .standardizedFileURL
    }

    static func terminalHintMatches(
        _ hint: PathTerminalHint,
        type: PathSegmentType
    ) -> Bool {
        switch hint {
        case .unspecified:
            return true

        case .file:
            return type == .file

        case .directory:
            return type == .directory
        }
    }

    static func relativePathIfDescendant(
        _ entry: PathWalkEntry,
        under root: URL
    ) -> StandardPath? {
        let root_path = StandardPath(
            fileURL: root,
            terminalHint: .directory,
            inferFileType: false
        )

        return entry.absolutePath.relative(to: root_path)
    }

    // static func relativePathIfDescendant(
    //     _ entry: PathWalkEntry,
    //     under root: URL
    // ) -> StandardPath? {
    //     let rootPath = StandardPath(
    //         fileURL: root,
    //         terminalHint: .directory,
    //         inferFileType: false
    //     )

    //     let candidate = entry.absolutePath

    //     let rootSegments = rootPath.segments.map(\.value)
    //     let candidateSegments = candidate.segments.map(\.value)

    //     guard
    //         candidateSegments.count >= rootSegments.count,
    //         Array(candidateSegments.prefix(rootSegments.count)) == rootSegments
    //     else {
    //         return nil
    //     }

    //     let relativeSegments = Array(
    //         candidate.segments.dropFirst(rootSegments.count)
    //     )

    //     return StandardPath(
    //         relativeSegments,
    //         filetype: candidate.filetype
    //     )
    // }
}
