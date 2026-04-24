public protocol PathTreeNodeKind: Sendable {
    static var expectedType: PathSegmentType? { get }
}

public enum PathTreeAnyNodeKind: PathTreeNodeKind {
    public static let expectedType: PathSegmentType? = nil
}

public enum PathTreeDirectoryKind: PathTreeNodeKind {
    public static let expectedType: PathSegmentType? = .directory
}

public enum PathTreeFileKind: PathTreeNodeKind {
    public static let expectedType: PathSegmentType? = .file
}

public extension PathTreeNodeKind {
    static func matches(
        _ node: PathTreeNode
    ) -> Bool {
        guard let expectedType else {
            return true
        }

        return node.type == expectedType
    }
}

public typealias PathTreeAnyNodeAddress = PathTreeAddress<PathTreeAnyNodeKind>
public typealias PathTreeDirectoryAddress = PathTreeAddress<PathTreeDirectoryKind>
public typealias PathTreeFileAddress = PathTreeAddress<PathTreeFileKind>

