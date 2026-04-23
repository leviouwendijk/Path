import Foundation

public enum FileTypeError: Error, Sendable {
    case unsupportedExtension(filename: String)
}

extension FileType {
    public var component: String {
        return ".\(self.rawValue)"
    }
}

extension FileType {
    public init?(fileExtension: String) {
        var file_ext: String = fileExtension

        if fileExtension.hasPrefix(".") {
            file_ext = String(file_ext.dropFirst())
        }

        file_ext = file_ext.lowercased()

        self.init(rawValue: file_ext)
    }

    public init(filename: String) throws {
        let lowercased = filename.lowercased()

        let sorted = Self.allCases
            .sorted { $0.component.count > $1.component.count }

        for ext in sorted {
            if lowercased.hasSuffix(ext.component) {
                self = ext
                return
            }
        }
        throw FileTypeError.unsupportedExtension(filename: filename)
    }
}
