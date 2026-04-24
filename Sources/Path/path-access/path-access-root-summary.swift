public struct PathAccessRootSummary: Sendable, Codable, Equatable, Hashable, Identifiable {
    public var rootIdentifier: PathAccessRootIdentifier
    public var label: String
    public var details: String?
    public var rootPath: String
    public var isDefault: Bool
    public var ruleCount: Int
    public var defaultDecision: PathAccessDecision
    public var diagnostics: [PathAccessRootDiagnostic]

    public init(
        rootIdentifier: PathAccessRootIdentifier,
        label: String,
        details: String? = nil,
        rootPath: String,
        isDefault: Bool,
        ruleCount: Int,
        defaultDecision: PathAccessDecision,
        diagnostics: [PathAccessRootDiagnostic] = []
    ) {
        self.rootIdentifier = rootIdentifier
        self.label = label
        self.details = details
        self.rootPath = rootPath
        self.isDefault = isDefault
        self.ruleCount = ruleCount
        self.defaultDecision = defaultDecision
        self.diagnostics = diagnostics
    }

    public var id: PathAccessRootIdentifier {
        rootIdentifier
    }
}

public extension PathAccessController {
    var summary: SummaryAPI {
        .init(
            controller: self
        )
    }

    struct SummaryAPI: Sendable, Codable, Hashable {
        public var controller: PathAccessController

        public init(
            controller: PathAccessController
        ) {
            self.controller = controller
        }

        public var roots: [PathAccessRootSummary] {
            controller.rootIdentifiers.compactMap { rootIdentifier in
                guard let root = controller.roots[rootIdentifier] else {
                    return nil
                }

                return summary(
                    for: root
                )
            }
        }

        public var defaultRoot: PathAccessRootSummary? {
            guard let rootIdentifier = controller.defaultRootIdentifier,
                  let root = controller.roots[rootIdentifier] else {
                return nil
            }

            return summary(
                for: root
            )
        }

        public var diagnostics: [PathAccessRootDiagnostic] {
            controller.diagnostics.all
        }
    }
}

private extension PathAccessController.SummaryAPI {
    func summary(
        for root: PathAccessRoot
    ) -> PathAccessRootSummary {
        .init(
            rootIdentifier: root.id,
            label: root.label,
            details: root.details,
            rootPath: root.rootPath,
            isDefault: root.id == controller.defaultRootIdentifier,
            ruleCount: root.scope.policy.rules.count,
            defaultDecision: root.scope.policy.default,
            diagnostics: diagnostics(
                for: root.id
            )
        )
    }

    func diagnostics(
        for rootIdentifier: PathAccessRootIdentifier
    ) -> [PathAccessRootDiagnostic] {
        diagnostics.filter {
            $0.rootIdentifier == rootIdentifier
                || $0.relatedRootIdentifier == rootIdentifier
        }
    }
}
