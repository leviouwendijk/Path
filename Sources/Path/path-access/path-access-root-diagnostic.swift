import Foundation

public enum PathAccessRootDiagnosticKind: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case missing_default_root
    case default_root_not_installed
    case duplicate_root
    case nested_root
}

public struct PathAccessRootDiagnostic: Sendable, Codable, Equatable, Hashable, Identifiable {
    public var kind: PathAccessRootDiagnosticKind
    public var rootIdentifier: PathAccessRootIdentifier?
    public var relatedRootIdentifier: PathAccessRootIdentifier?
    public var rootPath: String?
    public var relatedRootPath: String?
    public var message: String

    public init(
        kind: PathAccessRootDiagnosticKind,
        rootIdentifier: PathAccessRootIdentifier? = nil,
        relatedRootIdentifier: PathAccessRootIdentifier? = nil,
        rootPath: String? = nil,
        relatedRootPath: String? = nil,
        message: String
    ) {
        self.kind = kind
        self.rootIdentifier = rootIdentifier
        self.relatedRootIdentifier = relatedRootIdentifier
        self.rootPath = rootPath
        self.relatedRootPath = relatedRootPath
        self.message = message
    }

    public var id: String {
        [
            kind.rawValue,
            rootIdentifier?.rawValue ?? "-",
            relatedRootIdentifier?.rawValue ?? "-",
            rootPath ?? "-",
            relatedRootPath ?? "-"
        ].joined(separator: "|")
    }
}

public extension PathAccessController {
    var diagnostics: DiagnosticsAPI {
        .init(
            controller: self
        )
    }

    struct DiagnosticsAPI: Sendable, Codable, Hashable {
        public var controller: PathAccessController

        public init(
            controller: PathAccessController
        ) {
            self.controller = controller
        }

        public var all: [PathAccessRootDiagnostic] {
            defaultRootDiagnostics()
                + overlapDiagnostics()
        }

        public var roots: [PathAccessRootDiagnostic] {
            all
        }

        public var overlappingRoots: [PathAccessRootDiagnostic] {
            all.filter {
                switch $0.kind {
                case .duplicate_root,
                     .nested_root:
                    return true

                case .missing_default_root,
                     .default_root_not_installed:
                    return false
                }
            }
        }

        public var hasOverlappingRoots: Bool {
            !overlappingRoots.isEmpty
        }
    }
}

private extension PathAccessController.DiagnosticsAPI {
    func defaultRootDiagnostics() -> [PathAccessRootDiagnostic] {
        if controller.roots.isEmpty {
            return [
                .init(
                    kind: .missing_default_root,
                    message: "PathAccessController has no installed roots and therefore no default root."
                )
            ]
        }

        guard let defaultRootIdentifier = controller.defaultRootIdentifier else {
            return [
                .init(
                    kind: .missing_default_root,
                    message: "PathAccessController has installed roots but no default root."
                )
            ]
        }

        guard controller.roots[defaultRootIdentifier] != nil else {
            return [
                .init(
                    kind: .default_root_not_installed,
                    rootIdentifier: defaultRootIdentifier,
                    message: "PathAccessController default root '\(defaultRootIdentifier.rawValue)' is not installed."
                )
            ]
        }

        return []
    }

    func overlapDiagnostics() -> [PathAccessRootDiagnostic] {
        let roots = controller.roots.values.sorted {
            $0.id.rawValue < $1.id.rawValue
        }

        guard roots.count > 1 else {
            return []
        }

        var out: [PathAccessRootDiagnostic] = []

        for leftIndex in roots.indices {
            let rightStart = roots.index(after: leftIndex)

            guard rightStart < roots.endIndex else {
                continue
            }

            for rightIndex in rightStart..<roots.endIndex {
                out.append(
                    contentsOf: overlapDiagnostics(
                        left: roots[leftIndex],
                        right: roots[rightIndex]
                    )
                )
            }
        }

        return out
    }

    func overlapDiagnostics(
        left: PathAccessRoot,
        right: PathAccessRoot
    ) -> [PathAccessRootDiagnostic] {
        let leftDisplayPath = left.rootURL.standardizedFileURL.path
        let rightDisplayPath = right.rootURL.standardizedFileURL.path
        let leftPath = normalizedDirectoryPath(
            left.rootURL
        )
        let rightPath = normalizedDirectoryPath(
            right.rootURL
        )

        if leftPath == rightPath {
            return [
                .init(
                    kind: .duplicate_root,
                    rootIdentifier: left.id,
                    relatedRootIdentifier: right.id,
                    rootPath: leftDisplayPath,
                    relatedRootPath: rightDisplayPath,
                    message: "Path access roots '\(left.id.rawValue)' and '\(right.id.rawValue)' point at the same directory."
                )
            ]
        }

        if rightPath.hasPrefix(leftPath) {
            return [
                .init(
                    kind: .nested_root,
                    rootIdentifier: left.id,
                    relatedRootIdentifier: right.id,
                    rootPath: leftDisplayPath,
                    relatedRootPath: rightDisplayPath,
                    message: "Path access root '\(right.id.rawValue)' is nested inside root '\(left.id.rawValue)'."
                )
            ]
        }

        if leftPath.hasPrefix(rightPath) {
            return [
                .init(
                    kind: .nested_root,
                    rootIdentifier: right.id,
                    relatedRootIdentifier: left.id,
                    rootPath: rightDisplayPath,
                    relatedRootPath: leftDisplayPath,
                    message: "Path access root '\(left.id.rawValue)' is nested inside root '\(right.id.rawValue)'."
                )
            ]
        }

        return []
    }

    func normalizedDirectoryPath(
        _ url: URL
    ) -> String {
        let path = url.standardizedFileURL.path

        if path == "/" {
            return path
        }

        return path.hasSuffix("/")
            ? path
            : path + "/"
    }
}
