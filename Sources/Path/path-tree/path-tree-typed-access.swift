public struct PathTreeResolvedNode<Kind: PathTreeNodeKind>: Sendable, Equatable {
    public let address: PathTreeAddress<Kind>
    public let node: PathTreeNode

    public init(
        address: PathTreeAddress<Kind>,
        node: PathTreeNode
    ) {
        self.address = address
        self.node = node
    }

    public var path: StandardPath {
        address.path
    }
}

public extension PathTree {
    func node<Kind: PathTreeNodeKind>(
        at address: PathTreeAddress<Kind>
    ) -> PathTreeResolvedNode<Kind>? {
        guard let node = node(at: address.path),
              Kind.matches(node) else {
            return nil
        }

        return PathTreeResolvedNode(
            address: address,
            node: node
        )
    }

    func requireNode<Kind: PathTreeNodeKind>(
        at address: PathTreeAddress<Kind>
    ) throws -> PathTreeResolvedNode<Kind> {
        guard let rawNode = node(at: address.path) else {
            throw PathTreeLookupError.nodeNotFound(
                address.path,
                expected: Kind.expectedType
            )
        }

        guard Kind.matches(rawNode) else {
            throw PathTreeLookupError.nodeTypeMismatch(
                address.path,
                expected: Kind.expectedType,
                actual: rawNode.type
            )
        }

        return PathTreeResolvedNode(
            address: address,
            node: rawNode
        )
    }

    func contains<Kind: PathTreeNodeKind>(
        _ address: PathTreeAddress<Kind>
    ) -> Bool {
        node(at: address) != nil
    }

    func absolutePath<Kind: PathTreeNodeKind>(
        for address: PathTreeAddress<Kind>
    ) throws -> StandardPath {
        _ = try requireNode(at: address)

        if let relativePath = relative(address.path) {
            return try appending(relativePath)
        }

        return try appending(address.path)
    }
}
