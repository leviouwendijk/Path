import Foundation
import Path
import Methods

public enum WebReferenceConstraint: String, Codable, Hashable, CaseIterable, Sendable {
    /// At least one of origin, path, or fragment must exist.
    case requiresTarget

    /// Query items require an origin or a path.
    case requiresBaseForQuery
}

public typealias WebReferenceConstraints = Set<WebReferenceConstraint>

public enum WebReferenceConstraintSets {
    public static let standard: WebReferenceConstraints = [
        .requiresTarget,
        .requiresBaseForQuery
    ]

    public static let permissive: WebReferenceConstraints = []
}

public struct WebReferenceConstraintViolation: Error, LocalizedError, Sendable, Equatable {
    public let constraint: WebReferenceConstraint

    public let hasOrigin: Bool
    public let hasPath: Bool
    public let hasQuery: Bool
    public let hasFragment: Bool

    public init(
        constraint: WebReferenceConstraint,
        origin: String?,
        path: StandardPath?,
        query: [WebQueryItem],
        fragment: String?
    ) {
        let origin = origin.trimmedOrNil
        let query = WebQueryItem.normalized(query)
        let fragment = fragment.trimmedOrNil

        self.constraint = constraint
        self.hasOrigin = origin != nil
        self.hasPath = path != nil
        self.hasQuery = !query.isEmpty
        self.hasFragment = fragment != nil
    }

    public var shapeSummary: String {
        "origin=\(hasOrigin), path=\(hasPath), query=\(hasQuery), fragment=\(hasFragment)"
    }

    public var errorDescription: String? {
        switch constraint {
        case .requiresTarget:
            return "Web reference has no target."
        case .requiresBaseForQuery:
            return "Web reference query requires a base origin or path."
        }
    }

    public var failureReason: String? {
        switch constraint {
        case .requiresTarget:
            return "Origin, path, and fragment were all missing. Shape: \(shapeSummary)."
        case .requiresBaseForQuery:
            return "Query items were present without an origin or path. Shape: \(shapeSummary)."
        }
    }

    public var recoverySuggestion: String? {
        switch constraint {
        case .requiresTarget:
            return "Provide a path, an origin, or a fragment."
        case .requiresBaseForQuery:
            return "Provide an origin or path, or remove the query items."
        }
    }
}

public struct WebReferenceConstraintViolationError: Error, LocalizedError, Sendable, Equatable {
    public let violations: [WebReferenceConstraintViolation]

    public init(
        violations: [WebReferenceConstraintViolation]
    ) {
        self.violations = violations
    }

    public var errorDescription: String? {
        if violations.count == 1 {
            return violations[0].errorDescription
        }

        return "Web reference violated \(violations.count) constraints."
    }

    public var failureReason: String? {
        violations
            .compactMap { $0.failureReason }
            .joined(separator: " ")
    }

    public var recoverySuggestion: String? {
        let suggestions = violations
            .compactMap { $0.recoverySuggestion }

        guard !suggestions.isEmpty else {
            return nil
        }

        return suggestions.joined(separator: " ")
    }
}
