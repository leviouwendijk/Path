extension PathAccessPolicy {
    public static let defaults: DefaultsAPI = .init()

    public struct DefaultsAPI: Sendable {
        public init() {}

        public let workspace = PathAccessPolicy(
            default: .allow
        ) {
            deny {
                components(
                    ".build",
                    ".index-build",
                    "DerivedData",
                    reason: "Build and index output directories are excluded by default."
                )
                component(
                    ".git",
                    reason: "Git internals are excluded by default."
                )
                component(
                    ".agentic",
                    reason: "Agentic runtime state is excluded by default."
                )
                component(
                    "node_modules",
                    reason: "Dependency output is excluded by default."
                )

                basename(
                    ".env",
                    reason: "Environment files are excluded by default."
                )
                expression(
                    PathWorkspaceDefaultAccessPatterns.envVariant,
                    reason: "Environment file variants are excluded by default."
                )

                suffixes(
                    ".pem",
                    ".key",
                    ".p12",
                    ".pfx",
                    ".p8",
                    reason: "Private key, signing, and credential material is excluded by default."
                )
                suffixes(
                    ".cer",
                    ".crt",
                    ".der",
                    reason: "Certificate material is excluded by default."
                )
                suffixes(
                    ".mobileprovision",
                    ".mobileconfig",
                    reason: "Provisioning and device configuration profiles are excluded by default."
                )
                suffix(
                    ".ovpn",
                    reason: "VPN profiles are excluded by default."
                )

                suffixes(
                    ".sqlite",
                    ".db",
                    reason: "Database files can contain private state."
                )
            }
        }

        public let deny_all = PathAccessPolicy(
            default: .deny
        ) {}
    }
}

private enum PathWorkspaceDefaultAccessPatterns {
    static let envVariant = PathExpression(
        anchor: .relative,
        pattern: PathPattern(
            [
                .recursive,
                .componentPattern(".env.*")
            ],
            terminalHint: .file
        )
    )
}
