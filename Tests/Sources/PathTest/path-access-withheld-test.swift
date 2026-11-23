import Foundation
@_spi(Testing) import Path
import PathParsing

/// A recursive authorized scan leaves out paths a deny rule covers instead of
/// failing: the rest of the tree is still listed, and authorizing a denied
/// path directly stays denied.
func test_path_access_scan_withholds_denied() throws {
    let fileManager = FileManager.default
    let root = fileManager.temporaryDirectory
        .appendingPathComponent(
            "PathWithheld-\(UUID().uuidString)",
            isDirectory: true
        )

    defer {
        try? fileManager.removeItem(
            at: root
        )
    }

    let files = [
        "notes.md",
        "audio/take.wav",
        "archive/deep/nested/server.key",
        "archive/deep/signing.pem",
        "archive/deep/readme.txt",
    ]

    for file in files {
        let url = root.appendingPathComponent(
            file
        )
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("x".utf8).write(
            to: url
        )
    }

    let controller = PathAccessController.project(
        scope: try PathAccessScope(
            root: root
        )
    )
    let specification = try ParsedPathScan.specification(
        includes: [
            "**",
        ]
    )

    let result = try controller.scans.authorized(
        specification
    )
    let listed = Set(
        result.matches.map {
            $0.presentationPath
        }
    )

    for expected in [
        "notes.md",
        "audio/take.wav",
        "archive/deep/readme.txt",
    ] {
        try expect(
            listed.contains { $0.hasSuffix(expected) },
            "allowed path listed: \(expected) in \(listed.sorted())"
        )
    }

    try expect(
        !listed.contains { $0.hasSuffix(".key") || $0.hasSuffix(".pem") },
        "denied paths are not listed: \(listed.sorted())"
    )
    do {
        _ = try controller.authorize(
            "archive/deep/nested/server.key"
        )
        throw PathTestError.failed(
            "authorizing a denied path directly unexpectedly succeeded"
        )
    } catch PathAccessError.denied {
    }
}
