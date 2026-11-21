import Errors
import Foundation

extension WebReferenceConstraintViolation: ErrorNamespaced, ErrorDispositionProviding {
    public static let errorNamespace = "path.web_reference"
    public var errorCode: String { constraint.rawValue == "requiresTarget" ? "requires_target" : "requires_base_for_query" }
    public var errorDisposition: ErrorDisposition? { .invalid_input }
}
