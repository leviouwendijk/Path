// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Path",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "Path",
            targets: ["Path"]
        ),
        .library(
            name: "PathWeb",
            targets: ["PathWeb"]
        ),
        .library(
            name: "PathParsing",
            targets: ["PathParsing"]
        ),
    ],
    dependencies: [
        .swift_lco.IO,
        .swift_lco.FileTypes,
        .swift_lco.Primitives,
        .swift_lco.Methods,
        .swift_webc.ProtocolComponents,
        .swift_langs.Parsing,
        .swift_lco.Position,
        .swift_lco.Difference,
        .swift_lco.Errors,
    ],
    targets: [
        .target(
            name: "Path",
            dependencies: [
                .swift_lco.IO,
                .swift_lco.Position,
                .swift_lco.FileTypes,
                .swift_lco.Primitives,
                .swift_lco.Difference,
                .swift_lco.Errors,
            ]
        ),
        .target(
            name: "PathWeb",
            dependencies: [
                "Path",
                .swift_lco.Errors,
                .swift_lco.Methods,
                .swift_webc.ProtocolComponents,
            ]
        ),
        .target(
            name: "PathParsing",
            dependencies: [
                "Path",
                .swift_lco.Errors,
                .swift_langs.Parsing,
            ]
        ),
    ]
)

// convenience initializers
enum DependencyCatalog {
    struct Ref {
        let repo: String
        let package: String
        let product: String

        init(_ name: String) {
            self.repo = name
            self.package = name
            self.product = name
        }

        init(
            repo: String,
            package: String? = nil,
            product: String? = nil
        ) {
            self.repo = repo
            self.package = package ?? repo
            self.product = product ?? Self.productDefault(
                repo: repo,
                package: package
            )
        }

        private static func productDefault(
            repo: String,
            package: String?
        ) -> String {
            package ?? repo
        }
    }

    struct GitHubSource {
        let owner: String
        let defaultBranch: String

        init(
            owner: String,
            defaultBranch: String = "master"
        ) {
            self.owner = owner
            self.defaultBranch = defaultBranch
        }

        func package(
            _ ref: Ref
        ) -> Package.Dependency {
            .package(
                url: url(for: ref),
                branch: defaultBranch
            )
        }

        func package(
            _ ref: Ref,
            from version: Version
        ) -> Package.Dependency {
            .package(
                url: url(for: ref),
                from: version
            )
        }

        func package(
            _ ref: Ref,
            exact version: Version
        ) -> Package.Dependency {
            .package(
                url: url(for: ref),
                exact: version
            )
        }

        func package(
            _ ref: Ref,
            branch: String
        ) -> Package.Dependency {
            .package(
                url: url(for: ref),
                branch: branch
            )
        }

        func package(
            _ ref: Ref,
            revision: String
        ) -> Package.Dependency {
            .package(
                url: url(for: ref),
                revision: revision
            )
        }

        func product(
            _ ref: Ref,
            condition: TargetDependencyCondition? = nil
        ) -> Target.Dependency {
            .product(
                name: ref.product,
                package: ref.package,
                condition: condition
            )
        }

        private func url(
            for ref: Ref
        ) -> String {
            "https://github.com/\(owner)/\(ref.repo).git"
        }
    }

    @dynamicMemberLookup
    struct PackageNamespace<Catalog> {
        let source: GitHubSource
        let catalog: Catalog

        subscript(
            dynamicMember keyPath: KeyPath<Catalog, Ref>
        ) -> Package.Dependency {
            source.package(catalog[keyPath: keyPath])
        }

        func package(
            _ ref: Ref,
            from version: Version
        ) -> Package.Dependency {
            source.package(ref, from: version)
        }

        func package(
            _ ref: Ref,
            exact version: Version
        ) -> Package.Dependency {
            source.package(ref, exact: version)
        }

        func package(
            _ ref: Ref,
            branch: String
        ) -> Package.Dependency {
            source.package(ref, branch: branch)
        }

        func package(
            _ ref: Ref,
            revision: String
        ) -> Package.Dependency {
            source.package(ref, revision: revision)
        }
    }

    @dynamicMemberLookup
    struct ProductNamespace<Catalog> {
        let source: GitHubSource
        let catalog: Catalog

        subscript(
            dynamicMember keyPath: KeyPath<Catalog, Ref>
        ) -> Target.Dependency {
            source.product(catalog[keyPath: keyPath])
        }

        func product(
            _ ref: Ref,
            condition: TargetDependencyCondition? = nil
        ) -> Target.Dependency {
            source.product(ref, condition: condition)
        }
    }
}

enum Catalogs {
    static let swift_lco = SwiftLcoCatalog()
    static let swift_langs = SwiftLangsCatalog()
    static let swift_webc = SwiftWebcCatalog()
}

struct SwiftLcoCatalog {
    let IO = DependencyCatalog.Ref("IO")
    let FileTypes = DependencyCatalog.Ref("FileTypes")
    let Primitives = DependencyCatalog.Ref("Primitives")
    let Methods = DependencyCatalog.Ref("Methods")
    let Position = DependencyCatalog.Ref("Position")
    let Difference = DependencyCatalog.Ref("Difference")
    let Errors = DependencyCatalog.Ref("Errors")
}

struct SwiftLangsCatalog {
    let Parsing = DependencyCatalog.Ref("Parsing")
}

struct SwiftWebcCatalog {
    let ProtocolComponents = DependencyCatalog.Ref("ProtocolComponents")
}

extension Package.Dependency {
    static var swift_lco: DependencyCatalog.PackageNamespace<SwiftLcoCatalog> {
        .init(
            source: .init(owner: "swift-lco"),
            catalog: Catalogs.swift_lco
        )
    }

    static var swift_langs: DependencyCatalog.PackageNamespace<SwiftLangsCatalog> {
        .init(
            source: .init(owner: "swift-langs"),
            catalog: Catalogs.swift_langs
        )
    }

    static var swift_webc: DependencyCatalog.PackageNamespace<SwiftWebcCatalog> {
        .init(
            source: .init(owner: "swift-webc"),
            catalog: Catalogs.swift_webc
        )
    }
}

extension Target.Dependency {
    static var swift_lco: DependencyCatalog.ProductNamespace<SwiftLcoCatalog> {
        .init(
            source: .init(owner: "swift-lco"),
            catalog: Catalogs.swift_lco
        )
    }

    static var swift_langs: DependencyCatalog.ProductNamespace<SwiftLangsCatalog> {
        .init(
            source: .init(owner: "swift-langs"),
            catalog: Catalogs.swift_langs
        )
    }

    static var swift_webc: DependencyCatalog.ProductNamespace<SwiftWebcCatalog> {
        .init(
            source: .init(owner: "swift-webc"),
            catalog: Catalogs.swift_webc
        )
    }
}
