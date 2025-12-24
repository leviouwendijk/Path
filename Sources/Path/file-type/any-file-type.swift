public enum AnyFileType: Sendable, Codable, Hashable {
    case text(TextFile)
    case data(DataFile)
    case code(CodeFile)
    case document(DocumentFile)
    case spreadsheet(SpreadsheetFile)
    case presentation(PresentationFile)
    case photo(PhotoFile)
    case audio(AudioFile)
    case video(VideoFile)
    case archive(ArchiveFile)
    case font(FontFile)
    case diskImage(DiskImageFile)
    case database(DatabaseFile)
    case email(EmailFile)
    case calendar(CalendarFile)
    case cryptographic(CryptographicFile)
    case model3D(Model3DFile)
    case config(ConfigFile)

    public init(_ value: any FileType) {
        switch value {
        case let v as TextFile:          self = .text(v)
        case let v as DataFile:          self = .data(v)
        case let v as CodeFile:          self = .code(v)
        case let v as DocumentFile:      self = .document(v)
        case let v as SpreadsheetFile:   self = .spreadsheet(v)
        case let v as PresentationFile:  self = .presentation(v)
        case let v as PhotoFile:         self = .photo(v)
        case let v as AudioFile:         self = .audio(v)
        case let v as VideoFile:         self = .video(v)
        case let v as ArchiveFile:       self = .archive(v)
        case let v as FontFile:          self = .font(v)
        case let v as DiskImageFile:     self = .diskImage(v)
        case let v as DatabaseFile:      self = .database(v)
        case let v as EmailFile:         self = .email(v)
        case let v as CalendarFile:      self = .calendar(v)
        case let v as CryptographicFile: self = .cryptographic(v)
        case let v as Model3DFile:       self = .model3D(v)
        case let v as ConfigFile:        self = .config(v)
        default:
            preconditionFailure("Unhandled FileType: \(type(of: value))")
        }
    }

    public var base: any FileType {
        switch self {
        case .text(let v):          return v
        case .data(let v):          return v
        case .code(let v):          return v
        case .document(let v):      return v
        case .spreadsheet(let v):   return v
        case .presentation(let v):  return v
        case .photo(let v):         return v
        case .audio(let v):         return v
        case .video(let v):         return v
        case .archive(let v):       return v
        case .font(let v):          return v
        case .diskImage(let v):     return v
        case .database(let v):      return v
        case .email(let v):         return v
        case .calendar(let v):      return v
        case .cryptographic(let v): return v
        case .model3D(let v):       return v
        case .config(let v):        return v
        }
    }

    public var component: String {
        return self.base.component
    }
}
