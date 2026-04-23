import Foundation
import Path

public enum PathAccessParse {
    public static func matcher(
        _ raw: String
    ) throws -> PathAccessMatcher {
        let trimmed = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            throw PathParsingError.empty(location: nil)
        }

        if let remainder = trimmed.removingPrefix("component:") {
            return .component(
                try remainder.trimmedOrThrowing()
            )
        }

        if let remainder = trimmed.removingPrefix("basename:") {
            return .basename(
                try remainder.trimmedOrThrowing()
            )
        }

        if let remainder = trimmed.removingPrefix("suffix:") {
            return .suffix(
                try remainder.trimmedOrThrowing()
            )
        }

        return .expression(
            try PathParse.expression(trimmed)
        )
    }

    public static func rule(
        _ raw: String
    ) throws -> PathAccessRule {
        let trimmed = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            throw PathParsingError.empty(location: nil)
        }

        if let remainder = trimmed.removingPrefix("allow:") {
            return .allow(
                try matcher(remainder)
            )
        }

        if let remainder = trimmed.removingPrefix("deny:") {
            return .deny(
                try matcher(remainder)
            )
        }

        return .deny(
            try matcher(trimmed)
        )
    }

    public static func policy(
        _ rules: [String],
        defaultDecision: PathAccessDecision = .allow
    ) throws -> PathAccessPolicy {
        .init(
            rules: try rules.map(rule),
            defaultDecision: defaultDecision
        )
    }
}

private extension String {
    func removingPrefix(
        _ prefix: String
    ) -> String? {
        guard hasPrefix(prefix) else {
            return nil
        }

        return String(
            dropFirst(prefix.count)
        )
    }

    func trimmedOrThrowing() throws -> String {
        let trimmed = trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            throw PathParsingError.empty(location: nil)
        }

        return trimmed
    }
}
