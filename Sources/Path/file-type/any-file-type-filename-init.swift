public extension AnyFileType {
    init(filename: String) throws {
        for candidateType in Self.filenameClassificationOrder {
            if let value = try? candidateType.init(filename: filename) {
                self = Self(value)
                return
            }
        }

        throw FileTypeError.unsupportedExtension(filename: filename)
    }
}
