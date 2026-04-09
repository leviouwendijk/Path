import Foundation

public extension SegmentConcatenable {
    func present(
        _ options: PathPresentationOptions = .init()
    ) -> String {
        let allSegments = renderedSegments(
            includeFileType: options.filetype
        )

        let rendered: [String]

        switch options.style {
        case .full:
            rendered = allSegments

        case .relative(let base, let marker):
            rendered = relativeSegments(
                from: allSegments,
                base: base,
                includeFileType: options.filetype,
                marker: marker
            )

        case .dropFirst(let count):
            rendered = droppedLeadingSegments(
                from: allSegments,
                count: count,
                showOmittedCount: options.showOmittedCount
            )

        case .middleEllipsis(let keepFirst, let keepLast, let marker):
            rendered = middleEllipsizedSegments(
                from: allSegments,
                keepFirst: keepFirst,
                keepLast: keepLast,
                marker: marker,
                showOmittedCount: options.showOmittedCount
            )
        }

        return rendered.joined(separator: options.separator)
            .removed_double_slashes
    }

    func presentRelative(
        to base: StandardPath,
        marker: String = ".",
        separator: String = "/",
        filetype: Bool = true
    ) -> String {
        present(
            .init(
                style: .relative(
                    to: base,
                    marker: marker
                ),
                separator: separator,
                filetype: filetype
            )
        )
    }

    func presentDroppingFirst(
        _ count: Int,
        separator: String = "/",
        filetype: Bool = true,
        showOmittedCount: Bool = false
    ) -> String {
        present(
            .init(
                style: .dropFirst(count),
                separator: separator,
                filetype: filetype,
                showOmittedCount: showOmittedCount
            )
        )
    }

    func presentMiddleEllipsis(
        keepFirst: Int,
        keepLast: Int,
        marker: String = "…",
        separator: String = "/",
        filetype: Bool = true,
        showOmittedCount: Bool = false
    ) -> String {
        present(
            .init(
                style: .middleEllipsis(
                    keepFirst: keepFirst,
                    keepLast: keepLast,
                    marker: marker
                ),
                separator: separator,
                filetype: filetype,
                showOmittedCount: showOmittedCount
            )
        )
    }
}

private extension SegmentConcatenable {
    func renderedSegments(
        includeFileType: Bool
    ) -> [String] {
        var out = segments.map(\.value)

        if includeFileType, let filetype {
            if let last = out.popLast() {
                out.append(last + filetype.component)
            } else {
                out.append(filetype.component)
            }
        }

        return out
    }

    func relativeSegments(
        from allSegments: [String],
        base: StandardPath,
        includeFileType: Bool,
        marker: String
    ) -> [String] {
        let baseSegments = baseRenderedSegments(
            from: base,
            includeFileType: false
        )

        guard
            allSegments.count >= baseSegments.count,
            Array(allSegments.prefix(baseSegments.count)) == baseSegments
        else {
            return allSegments
        }

        let suffix = Array(allSegments.dropFirst(baseSegments.count))

        if suffix.isEmpty {
            return [marker]
        }

        return [marker] + suffix
    }

    func droppedLeadingSegments(
        from allSegments: [String],
        count: Int,
        showOmittedCount: Bool
    ) -> [String] {
        let safeCount = max(0, count)

        guard safeCount < allSegments.count else {
            if showOmittedCount, !allSegments.isEmpty {
                return ["…(\(allSegments.count))"]
            }

            return allSegments.isEmpty ? [] : ["…"]
        }

        let suffix = Array(allSegments.dropFirst(safeCount))

        guard showOmittedCount, safeCount > 0 else {
            return suffix
        }

        return ["…(\(safeCount))"] + suffix
    }

    func middleEllipsizedSegments(
        from allSegments: [String],
        keepFirst: Int,
        keepLast: Int,
        marker: String,
        showOmittedCount: Bool
    ) -> [String] {
        let firstCount = max(0, keepFirst)
        let lastCount = max(0, keepLast)

        guard allSegments.count > (firstCount + lastCount) else {
            return allSegments
        }

        let prefix = Array(allSegments.prefix(firstCount))
        let suffix = Array(allSegments.suffix(lastCount))
        let omittedCount = allSegments.count - prefix.count - suffix.count

        let middle: String = if showOmittedCount {
            "\(marker)(\(omittedCount))"
        } else {
            marker
        }

        return prefix + [middle] + suffix
    }

    func baseRenderedSegments(
        from base: StandardPath,
        includeFileType: Bool
    ) -> [String] {
        var out = base.segments.map(\.value)

        if includeFileType, let filetype = base.filetype {
            if let last = out.popLast() {
                out.append(last + filetype.component)
            } else {
                out.append(filetype.component)
            }
        }

        return out
    }
}
