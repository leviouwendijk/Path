import Foundation
import Path

func test_path_layout() throws {
    let year = PathField<Int>("year")
    let quarter = PathField<Int>("quarter")
    let month = PathField<Int>("month")
    let filename = PathField<String>("filename")
    let period = PathLayout(
        .capture(year), .capture(quarter), .capture(month)
    )
    let live = PathLayout(
        .literal("entries"), .include(period),
        .file(stem: filename, extension: "ec")
    )
    let archived = PathLayout(
        .literal("archive"), .literal("trash"), .include(period),
        .file(stem: filename, extension: "ec")
    )
    let path = StandardPath(["entries", "2026", "2", "4", "main.ec"])
    let decoded = try live.decode(path)
    try expect((try decoded.value(for: year)) == 2026, "typed year capture")
    try expect((try decoded.value(for: quarter)) == 2, "typed quarter capture")
    try expect((try decoded.value(for: month)) == 4, "typed month capture")
    try expect((try decoded.value(for: filename)) == "main", "file-stem capture")
    try expect(decoded.source(for: year)?.range == 1..<2, "capture provenance")
    try expect(
        try live.render(decoded.values).segments.map(\.value)
            == ["entries", "2026", "2", "4", "main.ec"],
        "typed render/decode round-trip"
    )
    do {
        _ = try archived.decode(path)
        throw PathTestError.failed("archive layout matched live entry")
    } catch PathLayoutError.noMatch {}

    let periodFile = PathLayout(
        .include(period), .file(stem: filename, extension: "ec")
    )
    let nested = StandardPath(["a", "b", "entries", "2026", "2", "4", "main.ec"])
    try expect(
        try periodFile.decode(nested, alignment: .suffix).value(for: year) == 2026,
        "arbitrary-length prefix via suffix alignment"
    )
    try expect(
        try periodFile.decode(nested, alignment: .after(["entries"])).value(for: month) == 4,
        "semantic anchor alignment"
    )
    do {
        _ = try periodFile.decode(
            StandardPath(["entries", "entries", "2026", "2", "4", "main.ec"]),
            alignment: .after(["entries"])
        )
        throw PathTestError.failed("repeated anchor accepted")
    } catch PathLayoutError.ambiguousMatch {}

    let category = PathField<String>("category")
    let subcategories = PathField<[String]>("subcategories")
    let entity = PathLayout(
        .literal("config"), .literal("entities"),
        .capture(category), .remainder(subcategories),
        .file(stem: filename, extension: "ec")
    )
    let entityMatch = try entity.decode(
        StandardPath(["config", "entities", "groups", "company", "bank.ec"])
    )
    try expect((try entityMatch.value(for: category)) == "groups", "category capture")
    try expect((try entityMatch.value(for: subcategories)) == ["company"], "middle remainder")
    try expect(
        try entity.render(entityMatch.values).segments.map(\.value)
            == ["config", "entities", "groups", "company", "bank.ec"],
        "variable-length render/decode round-trip"
    )
    let zeroMatch = try entity.decode(
        StandardPath(["config", "entities", "people", "owner.ec"])
    )
    try expect((try zeroMatch.value(for: subcategories)).isEmpty, "zero-length remainder")

    do {
        _ = try live.decode(StandardPath(["entries", "oops", "2", "4", "main.ec"]))
        throw PathTestError.failed("invalid integer capture accepted")
    } catch PathLayoutError.invalidCapture(let name, let raw) {
        try expect(name == "year" && raw == "oops", "invalid typed capture diagnostics")
    }
    do {
        _ = try PathLayout(.capture(year), .capture(year))
            .decode(StandardPath(["2026", "2026"]))
        throw PathTestError.failed("duplicate capture accepted")
    } catch PathLayoutError.duplicateField("year") {}
    do {
        _ = try live.render(.init())
        throw PathTestError.failed("missing rendering field accepted")
    } catch PathLayoutError.missingField("year") {}

    let padded = PathLayout(
        .capture(month, decode: { raw in
            guard let n = Int(raw), (1...12).contains(n) else {
                throw PathLayoutError.invalidCapture(name: "month", value: raw)
            }
            return n
        }, encode: { String(format: "%02d", $0) })
    )
    var monthValue = PathLayoutValues()
    monthValue.set(4, for: month)
    try expect(
        try padded.render(monthValue).segments.map(\.value) == ["04"],
        "canonical render formatting"
    )
    try expect(
        try padded.decode(StandardPath(["4"])).value(for: month) == 4,
        "noncanonical inputs decode to typed values"
    )
}
