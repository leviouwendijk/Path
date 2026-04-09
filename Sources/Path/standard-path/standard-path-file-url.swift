import Foundation

extension StandardPath {
    public init(
        fileURL url: URL,
        terminalHint: PathTerminalHint = .unspecified,
        inferFileType: Bool = false
    ) {
        let standardized = url.standardizedFileURL

        let components = standardized.pathComponents
            .filter { $0 != "/" }
            .filter { !$0.isEmpty }

        guard !components.isEmpty else {
            self.init()
            return
        }

        if inferFileType,
           terminalHint != .directory,
           let last = components.last,
           let parsedType = try? AnyFileType(filename: last) {
            let stem = String(
                last.dropLast(parsedType.component.count)
            )

            if !stem.isEmpty {
                var base = Array(components.dropLast())
                base.append(stem)

                self.init(
                    base,
                    filetype: parsedType
                )
                return
            }
        }

        self.init(components)
    }

    public init(
        rootPath path: String,
        filetype: AnyFileType? = nil
    ) {
        self.init(
            rawPath: path,
            filetype: filetype
        )
    }

    public var root_url: URL {
        self.root_url(filetype: true)
            .standardizedFileURL
    }

    public var directory_url: URL {
        self.root_url(filetype: false)
            .standardizedFileURL
    }
}

// extension StandardPath {
//     public init(fileURL url: URL) {
//         let standardized = url.standardizedFileURL

//         let comps = standardized.pathComponents
//             .filter { $0 != "/" }
//             .filter { !$0.isEmpty }

//         self.init(comps)
//     }

//     public init(rootPath path: String) {
//         self.init(
//             fileURL: URL(
//                 fileURLWithPath: path,
//                 isDirectory: true
//             )
//         )
//     }

//     public var root_url: URL {
//         self.root_url(filetype: true)
//             .standardizedFileURL
//     }

//     public var directory_url: URL {
//         self.root_url(filetype: false)
//             .standardizedFileURL
//     }
// }
