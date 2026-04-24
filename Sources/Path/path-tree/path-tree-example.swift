// public struct PackageTreeLayout: Sendable {
//     public let root: PathTreeDirectoryAddress

//     public init(
//         root: PathTreeDirectoryAddress = .root
//     ) {
//         self.root = root
//     }

//     public var sources: Sources {
//         Sources(
//             root: root.directory("Sources")
//         )
//     }

//     public var tests: Tests {
//         Tests(
//             root: root.directory("Tests")
//         )
//     }

//     public var package: PathTreeFileAddress {
//         root.file("Package.swift")
//     }

//     public struct Sources: Sendable {
//         public let root: PathTreeDirectoryAddress

//         public var path: PathModule {
//             PathModule(
//                 root: root.directory("Path")
//             )
//         }
//     }

//     public struct PathModule: Sendable {
//         public let root: PathTreeDirectoryAddress

//         public var tree: PathTreeFileAddress {
//             root.file("path-tree.swift")
//         }

//         public var node: PathTreeFileAddress {
//             root.file("path-tree-node.swift")
//         }

//         public var rendering: PathTreeFileAddress {
//             root.file("path-tree-rendering.swift")
//         }
//     }

//     public struct Tests: Sendable {
//         public let root: PathTreeDirectoryAddress

//         public var pathTests: PathTreeFileAddress {
//             root.file("PathTreeTests.swift")
//         }
//     }
// }

// let layout = PackageTreeLayout()

// let tree = PathTree(root: StandardPath(rawPath: "MyProject")) {
//     PathTreeNode.directory("Sources") {
//         PathTreeNode.directory("Path") {
//             PathTreeNode.file("path-tree.swift")
//             PathTreeNode.file("path-tree-node.swift")
//             PathTreeNode.file("path-tree-rendering.swift")
//         }
//     }

//     PathTreeNode.directory("Tests") {
//         PathTreeNode.file("PathTreeTests.swift")
//     }

//     PathTreeNode.file("Package.swift")
// }

// let sources = try tree.requireNode(at: layout.sources.root)
// let treeFile = try tree.requireNode(at: layout.sources.path.tree)
// let package = try tree.requireNode(at: layout.package)

// let packageAbsolutePath = try tree.absolutePath(for: layout.package)
