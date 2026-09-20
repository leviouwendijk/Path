import Darwin
import Foundation
import Path
import Primitives

enum PathTestError: Error {
    case failed(String)
}

func expect(
    _ condition: @autoclosure () throws -> Bool,
    _ message: String
) throws {
    guard try condition() else {
        throw PathTestError.failed(
            message
        )
    }
}

struct Fixture {
    let base: URL
    let root: URL
    let alpha: URL
    let nested: URL
    let rootFile: URL
    let childFile: URL
    let deepFile: URL
    let hiddenFile: URL
    let hiddenDirectory: URL
    let hiddenSecret: URL
    let externalRoot: URL
    let externalFile: URL
    let externalLink: URL
    let cycleLink: URL
}

func make_fixture() throws -> Fixture {
    let fileManager = FileManager.default

    let base = fileManager.temporaryDirectory
        .appendingPathComponent(
            "PathTest-\(UUID().uuidString)",
            isDirectory: true
        )

    let root = base.appendingPathComponent(
        "root",
        isDirectory: true
    )

    let alpha = root.appendingPathComponent(
        "alpha",
        isDirectory: true
    )

    let nested = alpha.appendingPathComponent(
        "nested",
        isDirectory: true
    )

    let hiddenDirectory = root.appendingPathComponent(
        ".hidden-directory",
        isDirectory: true
    )

    let externalRoot = base.appendingPathComponent(
        "external",
        isDirectory: true
    )

    try fileManager.createDirectory(
        at: nested,
        withIntermediateDirectories: true
    )

    try fileManager.createDirectory(
        at: hiddenDirectory,
        withIntermediateDirectories: true
    )

    try fileManager.createDirectory(
        at: externalRoot,
        withIntermediateDirectories: true
    )

    let rootFile = root.appendingPathComponent(
        "root.txt"
    )

    let childFile = alpha.appendingPathComponent(
        "child.txt"
    )

    let deepFile = nested.appendingPathComponent(
        "deep.txt"
    )

    let hiddenFile = root.appendingPathComponent(
        ".hidden.txt"
    )

    let hiddenSecret = hiddenDirectory.appendingPathComponent(
        "secret.txt"
    )

    let externalFile = externalRoot.appendingPathComponent(
        "external.txt"
    )

    try Data("root".utf8).write(
        to: rootFile
    )

    try Data("child".utf8).write(
        to: childFile
    )

    try Data("deep".utf8).write(
        to: deepFile
    )

    try Data("hidden".utf8).write(
        to: hiddenFile
    )

    try Data("secret".utf8).write(
        to: hiddenSecret
    )

    try Data("external".utf8).write(
        to: externalFile
    )

    let externalLink = root.appendingPathComponent(
        "external-link"
    )

    let cycleLink = externalRoot.appendingPathComponent(
        "root-cycle"
    )

    try fileManager.createSymbolicLink(
        at: externalLink,
        withDestinationURL: externalRoot
    )

    try fileManager.createSymbolicLink(
        at: cycleLink,
        withDestinationURL: root
    )

    return .init(
        base: base,
        root: root,
        alpha: alpha,
        nested: nested,
        rootFile: rootFile,
        childFile: childFile,
        deepFile: deepFile,
        hiddenFile: hiddenFile,
        hiddenDirectory: hiddenDirectory,
        hiddenSecret: hiddenSecret,
        externalRoot: externalRoot,
        externalFile: externalFile,
        externalLink: externalLink,
        cycleLink: cycleLink
    )
}

func urls(
    _ entries: [PathWalkEntry]
) -> Set<URL> {
    Set(
        entries.map { entry in
            entry.url.standardizedFileURL
        }
    )
}

func expected_urls(
    _ values: URL...
) -> Set<URL> {
    Set(
        values.map(\.standardizedFileURL)
    )
}

func test_standard_path() throws {
    let normalized = StandardPath(
        rawPath: "one/./two/../three"
    )

    try expect(
        normalized.segments.map(\.value) == [
            "one",
            "three",
        ],
        "StandardPath raw input normalization"
    )

    var appended = StandardPath(
        rawPath: "one/two"
    )

    appended.appendingSegments(
        "three",
        "four"
    )

    try expect(
        appended.segments.map(\.value) == [
            "one",
            "two",
            "three",
            "four",
        ],
        "StandardPath segment append"
    )
}

func test_path_tree() throws {
    var tree = PathTree(
        root: StandardPath(
            rawPath: "Project"
        )
    ) {
        PathTreeNode.directory(
            "Sources"
        ) {
            PathTreeNode.directory(
                "Core"
            ) {
                PathTreeNode.file(
                    "main.swift"
                )
            }
        }

        PathTreeNode.directory(
            "Tests"
        ) {
            PathTreeNode.file(
                "main-tests.swift"
            )
        }

        PathTreeNode.file(
            "Package.swift"
        )
    }

    let sourceFile = StandardPath(
        rawPath: "Project/Sources/Core/main.swift"
    )

    try expect(
        tree.contains(
            path: sourceFile
        ),
        "PathTree contains nested path"
    )

    try expect(
        tree.node(
            at: sourceFile
        )?.segment.value == "main.swift",
        "PathTree nested lookup"
    )

    try expect(
        !tree.contains(
            path: StandardPath(
                rawPath: "Project/Missing.swift"
            )
        ),
        "PathTree missing lookup"
    )

    try tree.appendDirectory(
        rawPath: "Generated"
    )

    try tree.appendFile(
        rawPath: "Generated/output.txt"
    )

    try expect(
        tree.contains(
            path: StandardPath(
                rawPath: "Project/Generated/output.txt"
            )
        ),
        "PathTree append creates nested file"
    )

    try tree.move(
        StandardPath(
            rawPath: "Project/Tests"
        ),
        under: StandardPath(
            rawPath: "Project/Sources"
        )
    )

    try expect(
        !tree.contains(
            path: StandardPath(
                rawPath: "Project/Tests/main-tests.swift"
            )
        ),
        "PathTree move removes old location"
    )

    try expect(
        tree.contains(
            path: StandardPath(
                rawPath: "Project/Sources/Tests/main-tests.swift"
            )
        ),
        "PathTree move preserves subtree"
    )

    try tree.rename(
        StandardPath(
            rawPath: "Project/Sources/Tests"
        ),
        to: "Specs"
    )

    try expect(
        tree.contains(
            path: StandardPath(
                rawPath: "Project/Sources/Specs/main-tests.swift"
            )
        ),
        "PathTree rename preserves descendants"
    )

    let beforeInvalidMove = tree
    var invalidMoveFailed = false

    do {
        try tree.move(
            StandardPath(
                rawPath: "Project/Sources"
            ),
            under: StandardPath(
                rawPath: "Project/Sources/Core"
            )
        )
    } catch {
        invalidMoveFailed = true
    }

    try expect(
        invalidMoveFailed,
        "PathTree rejects move into own descendant"
    )

    try expect(
        tree == beforeInvalidMove,
        "failed PathTree move is transactional"
    )
}

func test_path_tree_primitives_projection() throws {
    let tree = PathTree(
        root: StandardPath(
            rawPath: "Project"
        )
    ) {
        PathTreeNode.directory(
            "Sources"
        ) {
            PathTreeNode.directory(
                "Core"
            ) {
                PathTreeNode.file(
                    "main.swift"
                )
            }
        }

        PathTreeNode.file(
            "Package.swift"
        )
    }

    let primitiveTree = tree.primitive_tree

    let values = primitiveTree.walk().map { located in
        located.node.value
    }

    try expect(
        values.map { value in
            value.segment.value
        } == [
            "Sources",
            "Core",
            "main.swift",
            "Package.swift",
        ],
        "PathTree projection preserves topology and preorder"
    )

    try expect(
        values.map(\.type) == [
            .directory,
            .directory,
            .file,
            .file,
        ],
        "PathTree projection preserves Path segment kinds"
    )

    try expect(
        primitiveTree.roots.count == 2,
        "PathTree projection preserves first-level forest"
    )

    let sources = try TreeAddress(
        root: 0
    )

    let core = try TreeAddress(
        root: 0,
        descendants: [
            0,
        ]
    )

    let main = try TreeAddress(
        root: 0,
        descendants: [
            0,
            0,
        ]
    )

    try expect(
        primitiveTree.node(
            at: sources
        )?.value.segment.value == "Sources",
        "PathTree projection exposes first-level structural address"
    )

    try expect(
        primitiveTree.node(
            at: core
        )?.value.segment.value == "Core",
        "PathTree projection exposes nested structural address"
    )

    try expect(
        primitiveTree.node(
            at: main
        )?.value.segment.value == "main.swift",
        "PathTree projection exposes leaf structural address"
    )

    let segmentIndex = try primitiveTree.index { located in
        located.node.value.segment.value
    }

    try expect(
        segmentIndex.first_address(
            for: "main.swift"
        ) == main,
        "PathTree projection is indexable by Path semantic identity"
    )

    let mainCursor = try primitiveTree.cursor(
        at: main
    )

    try expect(
        mainCursor.parent?.address == core,
        "PathTree projection supports structural cursor ancestry"
    )

    try expect(
        mainCursor.parent?.parent?.address == sources,
        "PathTree projection supports structural cursor ancestry chain"
    )

    let encoded = try JSONEncoder().encode(
        tree
    )

    let decoded = try JSONDecoder().decode(
        PathTree.self,
        from: encoded
    )

    try expect(
        decoded == tree,
        "PathTree Codable round trip after Tree storage migration"
    )

    try expect(
        decoded.primitive_tree == primitiveTree,
        "PathTree Codable round trip preserves primitive topology"
    )

    guard let encodedObject = try JSONSerialization.jsonObject(
        with: encoded
    ) as? [String: Any] else {
        throw PathTestError.failed(
            "PathTree encoded representation is not an object"
        )
    }

    try expect(
        encodedObject["root"] != nil,
        "PathTree Codable preserves root key"
    )

    try expect(
        encodedObject["children"] != nil,
        "PathTree Codable preserves children key"
    )

    try expect(
        encodedObject["structure"] == nil,
        "PathTree internal Tree storage does not leak into Codable schema"
    )

    let sourcePath = StandardPath(
        rawPath: "Project/Sources/Core/main.swift"
    )

    try expect(
        tree.tree_address(
            for: sourcePath
        ) == main,
        "Path semantic path resolves to structural TreeAddress"
    )

    try expect(
        tree.semantic_path(
            at: main
        ) == sourcePath,
        "TreeAddress resolves back to semantic Path path"
    )

    try expect(
        tree.tree_address(
            for: tree.root
        ) == nil,
        "PathTree semantic root has no child-forest TreeAddress"
    )

    try expect(
        tree.contains(
            segment: "main.swift"
        ),
        "PathTree segment lookup uses Tree traversal"
    )

    try expect(
        !tree.contains(
            segment: "missing.swift"
        ),
        "PathTree Tree traversal rejects missing segment"
    )

    for modelPath in tree.modelPaths {
        guard let address = tree.tree_address(
            for: modelPath
        ) else {
            throw PathTestError.failed(
                "model path did not resolve to TreeAddress: \(modelPath)"
            )
        }

        try expect(
            tree.semantic_path(
                at: address
            ) == modelPath,
            "PathTree model path structurally round trips"
        )
    }
}

func test_path_tree_direct_insertion() throws {
    var tree = PathTree(
        root: StandardPath(
            rawPath: "Project"
        )
    ) {
        PathTreeNode.directory(
            "Sources"
        ) {
            PathTreeNode.file(
                "existing.swift"
            )
        }

        PathTreeNode.file(
            "Package.swift"
        )
    }

    let generated = StandardPath(
        rawPath: "Project/Sources/Generated/output.txt"
    )

    try tree.appendFile(
        generated
    )

    guard let generatedAddress = tree.tree_address(
        for: generated
    ) else {
        throw PathTestError.failed(
            "direct Tree insertion did not produce a structural address"
        )
    }

    try expect(
        tree.primitive_tree.node(
            at: generatedAddress
        )?.value.segment.value == "output.txt",
        "appendFile mutates stored Tree topology directly"
    )

    try expect(
        tree.node(
            at: generated
        )?.isFile == true,
        "direct Tree insertion remains visible through PathTreeNode compatibility API"
    )

    let extra = StandardPath(
        rawPath: "Project/Sources/extra.swift"
    )

    try tree.append(
        .file(
            "extra.swift"
        ),
        under: StandardPath(
            rawPath: "Project/Sources"
        )
    )

    try expect(
        tree.tree_address(
            for: extra
        ) != nil,
        "append under directory mutates stored Tree topology"
    )

    let beforeDuplicate = tree

    do {
        try tree.append(
            .file(
                "Package.swift"
            )
        )

        throw PathTestError.failed(
            "duplicate root insertion unexpectedly succeeded"
        )
    } catch PathTreeModelError.duplicateNode {
    }

    try expect(
        tree == beforeDuplicate,
        "failed direct Tree insertion is transactional"
    )

    try tree.append(
        .directory(
            "Package.swift"
        ),
        replacingExisting: true
    )

    try expect(
        tree.node(
            at: StandardPath(
                rawPath: "Project/Package.swift"
            )
        )?.isDirectory == true,
        "replacingExisting replaces matching Tree sibling"
    )
}

func test_path_tree_direct_move_rename() throws {
    var tree = PathTree(
        root: StandardPath(
            rawPath: "Project"
        )
    ) {
        PathTreeNode.directory(
            "Left"
        ) {
            PathTreeNode.directory(
                "Item"
            ) {
                PathTreeNode.file(
                    "source.txt"
                )
            }
        }

        PathTreeNode.directory(
            "Right"
        ) {
            PathTreeNode.directory(
                "Item"
            ) {
                PathTreeNode.file(
                    "stale.txt"
                )
            }
        }
    }

    let source = StandardPath(
        rawPath: "Project/Left/Item"
    )

    let destination = StandardPath(
        rawPath: "Project/Right"
    )

    let beforeDuplicateMove = tree

    do {
        try tree.move(
            source,
            under: destination
        )

        throw PathTestError.failed(
            "duplicate direct Tree move unexpectedly succeeded"
        )
    } catch PathTreeModelError.duplicateNode {
    }

    try expect(
        tree == beforeDuplicateMove,
        "failed direct Tree move is transactional"
    )

    try tree.move(
        source,
        under: destination,
        replacingExisting: true
    )

    let moved = StandardPath(
        rawPath: "Project/Right/Item"
    )

    let movedSource = StandardPath(
        rawPath: "Project/Right/Item/source.txt"
    )

    try expect(
        !tree.contains(
            path: source
        ),
        "direct Tree move removes semantic source"
    )

    try expect(
        tree.contains(
            path: movedSource
        ),
        "direct Tree move preserves moved subtree"
    )

    try expect(
        !tree.contains(
            path: StandardPath(
                rawPath: "Project/Right/Item/stale.txt"
            )
        ),
        "replacing direct Tree move removes destination subtree"
    )

    guard let movedAddress = tree.tree_address(
        for: moved
    ) else {
        throw PathTestError.failed(
            "moved semantic path did not resolve structurally"
        )
    }

    try expect(
        tree.primitive_tree.node(
            at: movedAddress
        )?.children.first?.value.segment.value == "source.txt",
        "move operates on stored generic Tree subtree"
    )

    try tree.rename(
        moved,
        to: "Renamed"
    )

    let renamed = StandardPath(
        rawPath: "Project/Right/Renamed"
    )

    let renamedSource = StandardPath(
        rawPath: "Project/Right/Renamed/source.txt"
    )

    try expect(
        !tree.contains(
            path: moved
        ),
        "direct Tree rename removes old semantic path"
    )

    try expect(
        tree.contains(
            path: renamedSource
        ),
        "direct Tree rename preserves subtree"
    )

    guard let renamedAddress = tree.tree_address(
        for: renamed
    ) else {
        throw PathTestError.failed(
            "renamed semantic path did not resolve structurally"
        )
    }

    try expect(
        tree.primitive_tree.node(
            at: renamedAddress
        )?.value.segment.value == "Renamed",
        "rename updates stored generic Tree value"
    )

    let beforeMissingRename = tree

    do {
        try tree.rename(
            StandardPath(
                rawPath: "Project/Right/Missing"
            ),
            to: "StillMissing"
        )

        throw PathTestError.failed(
            "missing direct Tree rename unexpectedly succeeded"
        )
    } catch PathTreeModelError.nodeNotFound {
    }

    try expect(
        tree == beforeMissingRename,
        "failed direct Tree rename is transactional"
    )
}

func test_path_tree_tree_rendering() throws {
    let tree = PathTree(
        root: StandardPath(
            rawPath: "Project"
        )
    ) {
        PathTreeNode.directory(
            "zeta"
        ) {
            PathTreeNode.file(
                "second.txt"
            )

            PathTreeNode.file(
                "first.txt"
            )
        }

        PathTreeNode.file(
            "alpha.txt"
        )
    }

    try expect(
        tree.render() == """
        Project/
            zeta/
                second.txt
                first.txt
            alpha.txt
        """,
        "PathTree Tree-backed rendering preserves natural preorder"
    )

    try expect(
        tree.render(
            indentation: "  ",
            includeRoot: false,
            includeTrailingSlashForDirectories: false,
            sortChildren: true
        ) == """
        alpha.txt
        zeta
          first.txt
          second.txt
        """,
        "PathTree Tree-backed rendering preserves sorting, depth, root omission, and slash options"
    )

    let node = PathTreeNode.directory(
        "node"
    ) {
        PathTreeNode.file(
            "child.txt"
        )
    }

    try expect(
        node.render() == """
        node/
            child.txt
        """,
        "PathTreeNode compatibility rendering remains available"
    )
}

func test_path_walker() throws {
    let fixture = try make_fixture()

    defer {
        try? FileManager.default.removeItem(
            at: fixture.base
        )
    }

    let defaultEntries = try PathWalker(
        root: fixture.root
    )
    .walk()

    try expect(
        urls(defaultEntries) == expected_urls(
            fixture.root,
            fixture.alpha,
            fixture.nested,
            fixture.rootFile,
            fixture.childFile,
            fixture.deepFile
        ),
        "default PathWalker traversal"
    )

    let depths = Dictionary(
        uniqueKeysWithValues: defaultEntries.map { entry in
            (
                entry.url.standardizedFileURL,
                entry.depth
            )
        }
    )

    try expect(
        depths[fixture.root.standardizedFileURL] == 0,
        "walker root depth"
    )

    try expect(
        depths[fixture.alpha.standardizedFileURL] == 1,
        "walker child directory depth"
    )

    try expect(
        depths[fixture.deepFile.standardizedFileURL] == 3,
        "walker nested file depth"
    )

    try expect(
        defaultEntries.first {
            $0.url.standardizedFileURL
                == fixture.root.standardizedFileURL
        }?.type == .directory,
        "walker root type"
    )

    try expect(
        defaultEntries.first {
            $0.url.standardizedFileURL
                == fixture.deepFile.standardizedFileURL
        }?.type == .file,
        "walker file type"
    )

    let hiddenEntries = try PathWalker(
        root: fixture.root,
        configuration: .init(
            includeHidden: true
        )
    )
    .walk()

    try expect(
        urls(hiddenEntries).isSuperset(
            of: expected_urls(
                fixture.hiddenFile,
                fixture.hiddenDirectory,
                fixture.hiddenSecret
            )
        ),
        "walker includes hidden subtree when requested"
    )

    let shallowEntries = try PathWalker(
        root: fixture.root,
        configuration: .init(
            maxDepth: 1
        )
    )
    .walk()

    try expect(
        urls(shallowEntries) == expected_urls(
            fixture.root,
            fixture.alpha,
            fixture.rootFile
        ),
        "walker maxDepth preserves current depth semantics"
    )

    let filesOnly = try PathWalker(
        root: fixture.root,
        configuration: .init(
            emitDirectories: false,
            emitFiles: true
        )
    )
    .walk()

    try expect(
        urls(filesOnly) == expected_urls(
            fixture.rootFile,
            fixture.childFile,
            fixture.deepFile
        ),
        "walker file-only emission"
    )

    let directoriesOnly = try PathWalker(
        root: fixture.root,
        configuration: .init(
            emitDirectories: true,
            emitFiles: false
        )
    )
    .walk()

    try expect(
        urls(directoriesOnly) == expected_urls(
            fixture.root,
            fixture.alpha,
            fixture.nested
        ),
        "walker directory-only emission"
    )

    let followedEntries = try PathWalker(
        root: fixture.root,
        configuration: .init(
            followSymlinks: true
        )
    )
    .walk()

    let followedURLs = urls(
        followedEntries
    )

    try expect(
        followedURLs.contains(
            fixture.externalRoot.standardizedFileURL
        ),
        "walker follows directory symlink when requested"
    )

    try expect(
        followedURLs.contains(
            fixture.externalFile.standardizedFileURL
        ),
        "walker traverses followed symlink target"
    )

    try expect(
        followedEntries.filter {
            $0.url.standardizedFileURL
                == fixture.root.standardizedFileURL
        }.count == 1,
        "walker resolved-URL revisit protection prevents symlink cycle"
    )

    let fileRootEntries = try PathWalker(
        root: fixture.rootFile
    )
    .walk()

    try expect(
        fileRootEntries.count == 1,
        "walker accepts file root"
    )

    try expect(
        fileRootEntries.first?.url.standardizedFileURL
            == fixture.rootFile.standardizedFileURL,
        "file-root walk emits root file"
    )

    try expect(
        fileRootEntries.first?.depth == 0,
        "file-root walk depth"
    )

    let missing = fixture.root.appendingPathComponent(
        "does-not-exist"
    )

    try expect(
        try PathWalker(
            root: missing
        ).walk().isEmpty,
        "walker missing root returns empty result"
    )
}

func run_path_tests() throws {
    try test_standard_path()
    try test_path_tree()
    try test_path_tree_primitives_projection()
    try test_path_tree_direct_insertion()
    try test_path_tree_direct_move_rename()
    try test_path_tree_tree_rendering()
    try test_path_walker()
}

do {
    try run_path_tests()

    print(
        "pathtest: passed"
    )
} catch {
    print(
        "pathtest: failed: \(error)"
    )

    exit(
        1
    )
}
