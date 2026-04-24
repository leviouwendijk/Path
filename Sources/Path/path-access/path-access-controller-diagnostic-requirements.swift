import Foundation

public enum PathAccessControllerDiagnosticError: Error, LocalizedError, Sendable, Equatable {
    case failed([PathAccessRootDiagnostic])

    public var errorDescription: String? {
        switch self {
        case .failed(let diagnostics):
            let messages = diagnostics.map(\.message).joined(
                separator: "\n"
            )

            return """
            Path access controller diagnostics failed:
            \(messages)
            """
        }
    }
}

public extension PathAccessController.DiagnosticsAPI {
    var require: RequireAPI {
        .init(
            diagnostics: self
        )
    }

    struct RequireAPI: Sendable, Codable, Hashable {
        public var diagnostics: PathAccessController.DiagnosticsAPI

        public init(
            diagnostics: PathAccessController.DiagnosticsAPI
        ) {
            self.diagnostics = diagnostics
        }

        public func clean() throws {
            let failures = diagnostics.all

            guard failures.isEmpty else {
                throw PathAccessControllerDiagnosticError.failed(
                    failures
                )
            }
        }

        public func defaultRoot() throws {
            let failures = diagnostics.all.filter {
                switch $0.kind {
                case .missing_default_root,
                     .default_root_not_installed:
                    return true

                case .duplicate_root,
                     .nested_root:
                    return false
                }
            }

            guard failures.isEmpty else {
                throw PathAccessControllerDiagnosticError.failed(
                    failures
                )
            }
        }

        public func noOverlaps() throws {
            let failures = diagnostics.overlappingRoots

            guard failures.isEmpty else {
                throw PathAccessControllerDiagnosticError.failed(
                    failures
                )
            }
        }
    }
}
