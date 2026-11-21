import Errors
import Foundation
@_spi(Testing) import Path

/// Path's errors through the Errors library: identity, disposition, a field,
/// and the text they already had.
func test_path_error_semantics() throws {
    var tree = PathTree(root: StandardPath(rawPath: "Project")) {
        PathTreeNode.file("Package.swift")
    }

    do {
        try tree.append(.file("Package.swift"))
        throw PathTestError.failed("duplicate insertion unexpectedly succeeded")
    } catch let error as PathTreeModelError {
        try expect(error.errorIdentity.raw == "path.tree_model.duplicate_node", "tree model identity: \(error.errorIdentity.raw)")
        try expect(error.report(for: .diagnostic).effectiveDisposition == .invalid_input, "tree model disposition")
    }

    let escape = PathSandboxError.pathEscapesSandbox(
        path: StandardPath(rawPath: "../outside.txt"),
        root: StandardPath(rawPath: "Project")
    )
    try expect(escape.errorIdentity.raw == "path.sandbox.path_escapes_sandbox", "sandbox identity")
    try expect(escape.errorDisposition == .invalid_input, "an escaping path is an input to change")
    let report = escape.report(for: .diagnostic)
    try expect(
        report.diagnostic.fields.contains { $0.name == "path" && $0.sensitivity == .potentially_sensitive },
        "sandbox path field is sensitive"
    )
    try expect(escape.explanation.contains("escapes sandbox"), "sandbox keeps its own text")

    let link = PathSandboxError.symlinkEscapesRoots(
        path: StandardPath(rawPath: "Project/link/file"),
        link: "link",
        destination: "/elsewhere"
    )
    try expect(link.errorDisposition == .requires_access, "a link out of the roots needs access")
}
