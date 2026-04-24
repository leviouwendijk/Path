public struct PathSensitivityProfile: Sendable, Codable, Equatable, Hashable, Identifiable {
    public var id: String
    public var rules: [PathSensitivityRule]

    public init(
        id: String,
        rules: [PathSensitivityRule] = []
    ) {
        self.id = id
        self.rules = rules
    }

    public static let empty = Self(
        id: "empty"
    )
}

public extension PathSensitivityProfile {
    func matchedRules(
        for path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> [PathSensitivityRule] {
        rules.filter {
            $0.matches(
                path,
                type: type
            )
        }
    }
}

public extension PathSensitivityProfile {
    static let agenticConservative = Self(
        id: "agentic_conservative",
        rules: alwaysSensitive
            + sensitiveComponents
            + probablySensitive
            + heavyOrNoisy
    )

    static let projectDefault = Self(
        id: "project_default",
        rules: alwaysSensitive
            + sensitiveComponents.filter {
                $0.id != "component:Library"
                    && $0.id != "component:.Trash"
            }
            + probablySensitive
            + heavyOrNoisy
    )

    static let broadRoot = Self(
        id: "broad_root",
        rules: alwaysSensitive
            + sensitiveComponents
            + probablySensitive
            + heavyOrNoisy
    )

    static let homePathOnly = Self(
        id: "home_path_only",
        rules: alwaysSensitive
            + sensitiveComponents
            + probablySensitive
            + heavyOrNoisy
    )
}

private extension PathSensitivityProfile {
    static var alwaysSensitive: [PathSensitivityRule] {
        [
            .basename(
                ".env",
                severity: .high,
                score: 120,
                reason: "Environment files commonly contain secrets.",
                action: .require_deny
            ),
            expressionRule(
                id: "expression:**/.env.*",
                pattern: [
                    .recursive,
                    .componentPattern(".env.*")
                ],
                severity: .high,
                score: 115,
                reason: "Environment variant files commonly contain secrets.",
                action: .require_deny,
                suggestedDeny: .expression
            ),
            .suffix(
                ".pem",
                severity: .critical,
                score: 180,
                reason: "PEM files often contain private keys or certificates.",
                action: .require_deny
            ),
            .suffix(
                ".key",
                severity: .critical,
                score: 180,
                reason: "Key files may contain private key material.",
                action: .require_deny
            ),
            .suffix(
                ".p12",
                severity: .critical,
                score: 170,
                reason: "PKCS#12 files may contain private credentials.",
                action: .require_deny
            ),
            .suffix(
                ".pfx",
                severity: .critical,
                score: 170,
                reason: "PFX files may contain private credentials.",
                action: .require_deny
            ),
            .suffix(
                ".mobileconfig",
                severity: .high,
                score: 130,
                reason: "Mobile configuration files may expose account or device configuration.",
                action: .suggest_deny
            ),
            .suffix(
                ".ovpn",
                severity: .high,
                score: 130,
                reason: "VPN profiles may contain private network configuration.",
                action: .suggest_deny
            ),
            .basename(
                "id_rsa",
                severity: .critical,
                score: 200,
                reason: "SSH private key basename.",
                action: .require_deny
            ),
            .basename(
                "id_dsa",
                severity: .critical,
                score: 200,
                reason: "SSH private key basename.",
                action: .require_deny
            ),
            .basename(
                "id_ecdsa",
                severity: .critical,
                score: 200,
                reason: "SSH private key basename.",
                action: .require_deny
            ),
            .basename(
                "id_ed25519",
                severity: .critical,
                score: 200,
                reason: "SSH private key basename.",
                action: .require_deny
            ),
            .basename(
                "credentials",
                severity: .high,
                score: 130,
                reason: "Credential file basename.",
                action: .require_deny
            ),
            expressionRule(
                id: "expression:**/credentials.*",
                pattern: [
                    .recursive,
                    .componentPattern("credentials.*")
                ],
                severity: .high,
                score: 125,
                reason: "Credential file pattern.",
                action: .require_deny,
                suggestedDeny: .expression
            ),
            expressionRule(
                id: "expression:**/secrets.*",
                pattern: [
                    .recursive,
                    .componentPattern("secrets.*")
                ],
                severity: .high,
                score: 125,
                reason: "Secret file pattern.",
                action: .require_deny,
                suggestedDeny: .expression
            ),
            expressionRule(
                id: "expression:**/token.*",
                pattern: [
                    .recursive,
                    .componentPattern("token.*")
                ],
                severity: .high,
                score: 120,
                reason: "Token file pattern.",
                action: .require_deny,
                suggestedDeny: .expression
            )
        ]
    }

    static var sensitiveComponents: [PathSensitivityRule] {
        [
            .component(
                ".ssh",
                severity: .critical,
                score: 190,
                reason: "SSH configuration and key directory.",
                action: .require_deny
            ),
            .component(
                ".aws",
                severity: .critical,
                score: 180,
                reason: "AWS credentials and configuration directory.",
                action: .require_deny
            ),
            .component(
                ".gnupg",
                severity: .critical,
                score: 180,
                reason: "GnuPG private key material directory.",
                action: .require_deny
            ),
            .component(
                ".kube",
                severity: .high,
                score: 150,
                reason: "Kubernetes configuration directory.",
                action: .require_deny
            ),
            .component(
                ".docker",
                severity: .high,
                score: 140,
                reason: "Docker configuration directory.",
                action: .suggest_deny
            ),
            .component(
                ".1password",
                severity: .critical,
                score: 200,
                reason: "Password manager data directory.",
                action: .require_deny
            ),
            .component(
                "Library",
                severity: .high,
                score: 130,
                reason: "Home Library can contain app-private data, tokens, caches, and key material.",
                action: .suggest_deny
            ),
            .component(
                ".Trash",
                severity: .medium,
                score: 80,
                reason: "Trash may contain unintended private files.",
                action: .suggest_deny
            )
        ]
    }

    static var probablySensitive: [PathSensitivityRule] {
        [
            .component(
                "Downloads",
                severity: .medium,
                score: 65,
                reason: "Downloads can contain arbitrary private files.",
                action: .warn_only
            ),
            .component(
                "Desktop",
                severity: .medium,
                score: 60,
                reason: "Desktop can contain private working files.",
                action: .warn_only
            ),
            .component(
                "Documents",
                severity: .medium,
                score: 60,
                reason: "Documents can contain personal files.",
                action: .warn_only
            ),
            expressionRule(
                id: "expression:**/*private*",
                pattern: [
                    .recursive,
                    .componentPattern("*private*")
                ],
                severity: .medium,
                score: 75,
                reason: "Path contains private marker.",
                action: .suggest_deny,
                suggestedDeny: .expression
            ),
            expressionRule(
                id: "expression:**/*secret*",
                pattern: [
                    .recursive,
                    .componentPattern("*secret*")
                ],
                severity: .high,
                score: 105,
                reason: "Path contains secret marker.",
                action: .suggest_deny,
                suggestedDeny: .expression
            ),
            expressionRule(
                id: "expression:**/*credential*",
                pattern: [
                    .recursive,
                    .componentPattern("*credential*")
                ],
                severity: .high,
                score: 105,
                reason: "Path contains credential marker.",
                action: .suggest_deny,
                suggestedDeny: .expression
            ),
            expressionRule(
                id: "expression:**/*token*",
                pattern: [
                    .recursive,
                    .componentPattern("*token*")
                ],
                severity: .high,
                score: 95,
                reason: "Path contains token marker.",
                action: .suggest_deny,
                suggestedDeny: .expression
            ),
            expressionRule(
                id: "expression:**/*do-not-read*",
                pattern: [
                    .recursive,
                    .componentPattern("*do-not-read*")
                ],
                severity: .high,
                score: 115,
                reason: "Path explicitly indicates it should not be read.",
                action: .require_deny,
                suggestedDeny: .expression
            ),
            expressionRule(
                id: "expression:**/*sensitive*",
                pattern: [
                    .recursive,
                    .componentPattern("*sensitive*")
                ],
                severity: .high,
                score: 110,
                reason: "Path contains sensitive marker.",
                action: .suggest_deny,
                suggestedDeny: .expression
            ),
            expressionRule(
                id: "expression:**/*confidential*",
                pattern: [
                    .recursive,
                    .componentPattern("*confidential*")
                ],
                severity: .high,
                score: 110,
                reason: "Path contains confidential marker.",
                action: .suggest_deny,
                suggestedDeny: .expression
            )
        ]
    }

    static var heavyOrNoisy: [PathSensitivityRule] {
        [
            .component(
                "node_modules",
                severity: .low,
                score: 30,
                reason: "node_modules is usually large and noisy for scans.",
                action: .warn_only
            ),
            .component(
                ".build",
                severity: .low,
                score: 30,
                reason: "Swift build output is usually large and noisy for scans.",
                action: .warn_only
            ),
            .component(
                "DerivedData",
                severity: .low,
                score: 30,
                reason: "DerivedData is usually large and noisy for scans.",
                action: .warn_only
            ),
            .component(
                ".cache",
                severity: .low,
                score: 25,
                reason: "Cache directories are usually large and noisy for scans.",
                action: .warn_only
            ),
            .component(
                ".git",
                severity: .medium,
                score: 70,
                reason: "Git internals may expose history, refs, and configuration.",
                action: .suggest_deny
            ),
            .component(
                ".index-build",
                severity: .low,
                score: 25,
                reason: "Index build output is usually large and noisy for scans.",
                action: .warn_only
            )
        ]
    }

    static func expressionRule(
        id: String,
        pattern: [PathPatternComponent],
        severity: PathSensitivitySeverity,
        score: Int,
        reason: String,
        action: PathSensitivityAction,
        suggestedDeny: PathDenySuggestionKind?
    ) -> PathSensitivityRule {
        .init(
            id: id,
            matcher: .expression(
                PathExpression(
                    pattern: PathPattern(pattern)
                )
            ),
            severity: severity,
            score: score,
            reason: reason,
            action: action,
            suggestedDeny: suggestedDeny
        )
    }
}
