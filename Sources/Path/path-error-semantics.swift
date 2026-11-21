import Errors
import Foundation

/// Path's errors keep their own text, which already reads well, and gain an
/// identity, a disposition and the path involved as a (sensitive) field.

private extension StandardPath {
    var errorField: ErrorDiagnosticField {
        .init(key: .path, value: .string(render(as: .root, filetype: true)), sensitivity: .potentially_sensitive)
    }
}

extension PathAccessError: ErrorNamespaced, ErrorDispositionProviding, ErrorDiagnosticFieldsProviding {
    public static let errorNamespace = "path.access"
    public var errorCode: String { "denied" }
    public var errorDisposition: ErrorDisposition? { .requires_access }

    public var errorDiagnosticFields: [ErrorDiagnosticField] {
        switch self {
        case .denied(let evaluation):
            var fields: [ErrorDiagnosticField] = [
                .init(
                    key: .path,
                    value: .string(evaluation.path.presentingRelative(filetype: true)),
                    sensitivity: .potentially_sensitive
                ),
            ]
            if let rule = evaluation.matchedRule {
                fields.append(.init(key: "path.rule", value: .string(rule.matcher.summary)))
            }
            return fields
        }
    }
}

extension PathSandboxError: ErrorNamespaced, ErrorDispositionProviding, ErrorDiagnosticFieldsProviding {
    public static let errorNamespace = "path.sandbox"

    public var errorCode: String {
        switch self {
        case .rootMustBeDirectory: return "root_must_be_directory"
        case .pathEscapesSandbox: return "path_escapes_sandbox"
        case .symlinkNotFollowed: return "symlink_not_followed"
        case .symlinkEscapesRoots: return "symlink_escapes_roots"
        case .symlinkLoop: return "symlink_loop"
        }
    }

    public var errorDisposition: ErrorDisposition? {
        switch self {
        case .rootMustBeDirectory: return .requires_configuration
        case .pathEscapesSandbox, .symlinkLoop: return .invalid_input
        case .symlinkNotFollowed, .symlinkEscapesRoots: return .requires_access
        }
    }

    public var errorDiagnosticFields: [ErrorDiagnosticField] {
        switch self {
        case .rootMustBeDirectory(let path), .pathEscapesSandbox(let path, _), .symlinkLoop(let path):
            return [path.errorField]
        case .symlinkNotFollowed(let path, let link):
            return [path.errorField, .init(key: "path.link", value: .string(link), sensitivity: .potentially_sensitive)]
        case .symlinkEscapesRoots(let path, let link, let destination):
            return [
                path.errorField,
                .init(key: "path.link", value: .string(link), sensitivity: .potentially_sensitive),
                .init(key: "path.link_destination", value: .string(destination), sensitivity: .potentially_sensitive),
            ]
        }
    }
}

extension DescendantPathError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.descendant"

    public var errorCode: String {
        switch self {
        case .rootMustBeDirectory: return "root_must_be_directory"
        case .notDescendant: return "not_descendant"
        }
    }

    public var errorDisposition: ErrorDisposition? {
        switch self {
        case .rootMustBeDirectory: return .requires_configuration
        case .notDescendant: return .invalid_input
        }
    }
}

extension PathAccessControllerError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.roots"

    public var errorCode: String {
        switch self {
        case .rootNotFound: return "root_not_found"
        case .defaultRootUnavailable: return "default_root_unavailable"
        case .rootMismatch: return "root_mismatch"
        }
    }

    public var errorDisposition: ErrorDisposition? {
        switch self {
        case .rootNotFound, .rootMismatch: return .invalid_input
        case .defaultRootUnavailable: return .requires_configuration
        }
    }
}

extension PathAccessControllerDiagnosticError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.roots"
    public var errorCode: String { "diagnostics_failed" }
    public var errorDisposition: ErrorDisposition? { .requires_configuration }
}

extension PathResolveError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.resolve"
    public var errorCode: String { "empty_input" }
    public var errorDisposition: ErrorDisposition? { .invalid_input }
}

extension PathTreeLookupError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.tree"

    public var errorCode: String {
        switch self {
        case .nodeNotFound: return "node_not_found"
        case .nodeTypeMismatch: return "node_type_mismatch"
        }
    }

    public var errorDisposition: ErrorDisposition? { .invalid_input }
}

extension PathTreeModelError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.tree_model"

    public var errorCode: String {
        switch self {
        case .emptyRelativePath: return "empty_relative_path"
        case .cannotMoveRoot: return "cannot_move_root"
        case .cannotMoveNodeIntoItself: return "cannot_move_into_itself"
        case .nodeNotFound: return "node_not_found"
        case .destinationNotFound: return "destination_not_found"
        case .destinationIsFile: return "destination_is_file"
        case .duplicateNode: return "duplicate_node"
        }
    }

    public var errorDisposition: ErrorDisposition? { .invalid_input }
}

extension PathTreeDifferenceError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.tree_difference"
    public var errorCode: String { "mismatched_roots" }
    public var errorDisposition: ErrorDisposition? { .invalid_input }
}

extension PathLayoutError: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.layout"

    public var errorCode: String {
        switch self {
        case .invalidLayout: return "invalid_layout"
        case .duplicateField: return "duplicate_field"
        case .noMatch: return "no_match"
        case .ambiguousMatch: return "ambiguous_match"
        case .invalidCapture: return "invalid_capture"
        case .missingField: return "missing_field"
        case .invalidRenderedSegment: return "invalid_rendered_segment"
        }
    }

    public var errorDisposition: ErrorDisposition? {
        switch self {
        case .invalidLayout, .duplicateField: return .requires_configuration
        default: return .invalid_input
        }
    }
}
