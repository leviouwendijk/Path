import Foundation

public enum PathSegmentType: String, RawRepresentable, Sendable, Codable {
    case directory
    case file

    public static func from(_ is_dir_obj_c: ObjCBool) -> Self {
        return  is_dir_obj_c.boolValue ? .directory : .file
    }
}
