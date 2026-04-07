// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Path",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Path",
            targets: ["Path"]
        ),
        .library(
            name: "PathWeb",
            targets: ["PathWeb"]
        )
    ],
    dependencies: [
        .leviouwendijk.Methods,
        .leviouwendijk.ProtocolComponents,
    ],
    targets: [
        .target(
            name: "Path",
        ),
        .target(
            name: "PathWeb",
            dependencies: [
                "Path",
                .leviouwendijk.Methods,
                .leviouwendijk.ProtocolComponents,
            ]
        ),
        // .testTarget(
        //     name: "PathTests",
        //     dependencies: ["Path"]
        // ),
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
    static let leviouwendijk = LeviOuwendijkCatalog()
}

struct LeviOuwendijkCatalog {
    let HTTP = DependencyCatalog.Ref("HTTP")
    let Server = DependencyCatalog.Ref("Server")
    let Milieu = DependencyCatalog.Ref("Milieu")
    let Loggers = DependencyCatalog.Ref("Loggers")
    let Cryptography = DependencyCatalog.Ref("Cryptography")

    let Primitives = DependencyCatalog.Ref("Primitives")
    let Methods = DependencyCatalog.Ref("Methods")
    let Variables = DependencyCatalog.Ref("Variables")
    let Writers = DependencyCatalog.Ref("Writers")
    let ProtocolComponents = DependencyCatalog.Ref("ProtocolComponents")

    let plate = DependencyCatalog.Ref("plate")
    let Structures = DependencyCatalog.Ref("Structures")
    let Extensions = DependencyCatalog.Ref("Extensions")
    let Interfaces = DependencyCatalog.Ref("Interfaces")
    let Parsers = DependencyCatalog.Ref("Parsers")
    let Constructors = DependencyCatalog.Ref("Constructors")

    let Surfaces = DependencyCatalog.Ref("Surfaces")
    let Vaporized = DependencyCatalog.Ref("Vaporized")

    // repo != product
    let PklSwift = DependencyCatalog.Ref(
        repo: "pkl-swift",
        product: "PklSwift"
    )
}

extension Package.Dependency {
    static var leviouwendijk: DependencyCatalog.PackageNamespace<LeviOuwendijkCatalog> {
        .init(
            source: .init(owner: "leviouwendijk"),
            catalog: Catalogs.leviouwendijk
        )
    }
}

extension Target.Dependency {
    static var leviouwendijk: DependencyCatalog.ProductNamespace<LeviOuwendijkCatalog> {
        .init(
            source: .init(owner: "leviouwendijk"),
            catalog: Catalogs.leviouwendijk
        )
    }
}
