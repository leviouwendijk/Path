public enum PathSensitivityEvidenceSource: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case path
    case metadata
    case content_probe
}

public enum PathSensitivitySeverity: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
    case low
    case medium
    case high
    case critical
}

public extension PathSensitivitySeverity {
    var weight: Int {
        switch self {
        case .low:
            return 1

        case .medium:
            return 2

        case .high:
            return 3

        case .critical:
            return 4
        }
    }

    static func highest(
        _ values: [Self]
    ) -> Self {
        values.max {
            $0.weight < $1.weight
        } ?? .low
    }
}

public struct PathSensitivityScoreComponent: Sendable, Codable, Equatable, Hashable {
    public var name: String
    public var value: Int
    public var detail: String?
    public var source: PathSensitivityEvidenceSource

    public init(
        name: String,
        value: Int,
        detail: String? = nil,
        source: PathSensitivityEvidenceSource = .path
    ) {
        self.name = name
        self.value = value
        self.detail = detail
        self.source = source
    }
}

public struct PathSensitivityScore: Sendable, Codable, Equatable, Hashable, Comparable, CustomStringConvertible {
    public var value: Int
    public var components: [PathSensitivityScoreComponent]

    public init(
        value: Int,
        components: [PathSensitivityScoreComponent] = []
    ) {
        self.value = value
        self.components = components
    }

    public static let zero = Self(
        value: 0
    )

    public var isZero: Bool {
        value == 0
    }

    public var description: String {
        "\(value)"
    }

    public func adding(
        _ component: PathSensitivityScoreComponent
    ) -> Self {
        .init(
            value: value + component.value,
            components: components + [component]
        )
    }

    public func adding(
        value: Int,
        name: String,
        detail: String? = nil,
        source: PathSensitivityEvidenceSource = .path
    ) -> Self {
        adding(
            .init(
                name: name,
                value: value,
                detail: detail,
                source: source
            )
        )
    }

    public static func < (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.value < rhs.value
    }
}
