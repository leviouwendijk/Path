import Difference
import Path

func test_path_tree_difference_semantics() throws {
    let baseline = PathTree(root: StandardPath(rawPath: "sandbox"), children: [
        .directory("Sources", children: [
            .file("main"),
            .file("other")
        ])
    ])
    let proposed = PathTree(root: StandardPath(rawPath: "sandbox"), children: [
        .directory("Sources", children: [
            .file("main"),
            .file("added")
        ])
    ])
    let changed = try PathTree.difference(
        before: baseline, after: proposed, source: .planned
    )
    let nodes = changed.tree.walk().map { $0.node.value }
    let added = nodes.first { $0.after?.path.segments.last?.value == "added" }
    let removed = nodes.first { $0.before?.path.segments.last?.value == "other" }
    try expect(changed.source == .planned, "path tree keeps supplied provenance")
    try expect(added?.change == .added, "new paths are additions")
    try expect(removed?.change == .removed, "missing paths are removals")
    try expect(
        nodes.filter { $0.label == "main" }.count == 1,
        "full-path node identity does not collide with its sibling"
    )
    let repeated_names = PathTree(root: baseline.root, children: [
        .directory("Sources", children: [.file("common")]),
        .directory("Tests", children: [.file("common")])
    ])
    let repeated_diff = try PathTree.difference(
        before: PathTree(root: baseline.root), after: repeated_names
    )
    try expect(
        repeated_diff.tree.walk().filter { $0.node.value.label == "common" }.count == 2,
        "same basename in separate directories has distinct full-path identities"
    )

    let renamed = PathTree(root: baseline.root, children: [
        .directory("Sources", children: [
            .file("renamed"), .file("other")
        ])
    ])
    let rename_without_identity = try PathTree.difference(
        before: baseline, after: renamed, source: .proposed
    )
    let before_id = rename_without_identity.tree.walk().first {
        $0.node.value.before?.path.segments.last?.value == "main"
    }
    try expect(before_id?.node.value.change == .removed, "a rename is not guessed without identity")

    let renamed_with_identity = try PathTree.difference(
        before: baseline, after: renamed, source: .planned,
        identity: { path in
            let last = path.segments.last?.value ?? ""
            return last == "renamed" ? "sandbox/Sources/main" :
                path.render(as: .relative, filetype: true)
        }
    )
    let moved = renamed_with_identity.tree.walk().first {
        $0.node.value.id == "sandbox/Sources/main"
    }
    try expect(moved?.node.value.change == .moved, "explicit stable identity classifies rename")
    try expect(
        moved?.node.value.before?.path != moved?.node.value.after?.path,
        "before and after paths both survive"
    )

    do {
        _ = try PathTree.difference(
            before: baseline,
            after: PathTree(root: StandardPath(rawPath: "another"))
        )
        throw PathTestError.failed("mismatched roots were accepted")
    } catch PathTreeDifferenceError.mismatched_roots {
        // Intended failure.
    }
}
