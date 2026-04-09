import Foundation

public extension StandardPath {
    var lastSegment: PathSegment? {
        segments.last
    }

    func lastComponent(
        filetype includeFileType: Bool = true
    ) -> String? {
        guard let lastSegment else {
            if includeFileType, let filetype {
                return filetype.component
            }

            return nil
        }

        guard includeFileType, let filetype else {
            return lastSegment.value
        }

        return lastSegment.value + filetype.component
    }

    /// Last rendered component, including file extension when present.
    var basename: String? {
        lastComponent(filetype: true)
    }

    /// Last path segment without file extension decoration.
    var stem: String? {
        lastComponent(filetype: false)
    }

    var parentDirectoryName: String? {
        guard segments.count >= 2 else {
            return nil
        }

        return segments[segments.count - 2].value
    }

    var isRoot: Bool {
        segments.isEmpty && filetype == nil
    }

    func presentRelativeToCWD(
        marker: String = ".",
        separator: String = "/",
        filetype: Bool = true
    ) -> String {
        presentRelative(
            to: .cwd,
            marker: marker,
            separator: separator,
            filetype: filetype
        )
    }

    func presentRelativeToHome(
        marker: String = "~",
        separator: String = "/",
        filetype: Bool = true
    ) -> String {
        presentRelative(
            to: .home,
            marker: marker,
            separator: separator,
            filetype: filetype
        )
    }
}

