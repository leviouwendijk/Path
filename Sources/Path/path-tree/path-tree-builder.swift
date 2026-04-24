@resultBuilder
public enum PathTreeBuilder {
    public static func buildBlock(
        _ components: [PathTreeNode]...
    ) -> [PathTreeNode] {
        components.flatMap { $0 }
    }

    public static func buildExpression(
        _ expression: PathTreeNode
    ) -> [PathTreeNode] {
        [expression]
    }

    public static func buildExpression(
        _ expression: [PathTreeNode]
    ) -> [PathTreeNode] {
        expression
    }

    public static func buildOptional(
        _ component: [PathTreeNode]?
    ) -> [PathTreeNode] {
        component ?? []
    }

    public static func buildEither(
        first component: [PathTreeNode]
    ) -> [PathTreeNode] {
        component
    }

    public static func buildEither(
        second component: [PathTreeNode]
    ) -> [PathTreeNode] {
        component
    }

    public static func buildArray(
        _ components: [[PathTreeNode]]
    ) -> [PathTreeNode] {
        components.flatMap { $0 }
    }
}
