@dynamicMemberLookup
public struct FileTypeNamespace<T: FileType>: Sendable {
    public init() {}

    public subscript(dynamicMember member: String) -> T {
        guard let value = T(rawValue: member) else {
            preconditionFailure("Unknown \(T.self) file type: \(member)")
        }
        return value
    }
}

// convenience api
public enum FileTypes {
    public static let text = FileTypeNamespace<TextFile>()
    public static let data = FileTypeNamespace<DataFile>()
    public static let code = FileTypeNamespace<CodeFile>()
    public static let document = FileTypeNamespace<DocumentFile>()
    public static let spreadsheet = FileTypeNamespace<SpreadsheetFile>()
    public static let presentation = FileTypeNamespace<PresentationFile>()
    public static let photo = FileTypeNamespace<PhotoFile>()
    public static let audio = FileTypeNamespace<AudioFile>()
    public static let video = FileTypeNamespace<VideoFile>()
    public static let archive = FileTypeNamespace<ArchiveFile>()
    public static let font = FileTypeNamespace<FontFile>()
    public static let diskImage = FileTypeNamespace<DiskImageFile>()
    public static let database = FileTypeNamespace<DatabaseFile>()
    public static let email = FileTypeNamespace<EmailFile>()
    public static let calendar = FileTypeNamespace<CalendarFile>()
    public static let cryptographic = FileTypeNamespace<CryptographicFile>()
    public static let model3D = FileTypeNamespace<Model3DFile>()
    public static let config = FileTypeNamespace<ConfigFile>()
}
