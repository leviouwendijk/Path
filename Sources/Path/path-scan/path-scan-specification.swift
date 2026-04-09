public struct PathScanSpecification: Sendable, Codable, Equatable {
    public var includes: [PathExpression]
    public var excludes: [PathExpression]
    public var selections: [PathSelectionExpression]

    public init(
        includes: [PathExpression] = [],
        excludes: [PathExpression] = [],
        selections: [PathSelectionExpression] = []
    ) {
        self.includes = includes
        self.excludes = excludes
        self.selections = selections
    }
}

public extension PathScanSpecification {
    var positiveExpressions: [PathExpression] {
        includes + selections.map(\.path)
    }

    var isEmpty: Bool {
        includes.isEmpty
            && excludes.isEmpty
            && selections.isEmpty
    }
}
