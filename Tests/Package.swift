// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PathTests",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "t_path",
            targets: ["PathTest"]
        ),
    ],
    dependencies: [
        .swift_lco.IO,
        .swift_lco.Primitives,
        .swift_lco.Difference,
        .swift_lco.Errors,
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "PathTest",
            dependencies: [
                .product(name: "Path", package: "Path"),
                .product(name: "PathParsing", package: "Path"),
                .swift_lco.IO,
                .swift_lco.Primitives,
                .swift_lco.Difference,
                .swift_lco.Errors,
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
}

struct SwiftLcoCatalog {
    let IO = DependencyCatalog.Ref("IO")
    let Primitives = DependencyCatalog.Ref("Primitives")
    let Difference = DependencyCatalog.Ref("Difference")
    let Errors = DependencyCatalog.Ref("Errors")
}

extension Package.Dependency {
    static var swift_lco: DependencyCatalog.PackageNamespace<SwiftLcoCatalog> {
        .init(
            source: .init(owner: "swift-lco"),
            catalog: Catalogs.swift_lco
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
}
