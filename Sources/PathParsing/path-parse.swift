import Parsing
import Path

public enum PathParse {
    public static let expressionParser = PathExpressionParser()

    public static func expression(
        _ raw: String
    ) throws -> PathExpression {
        try PathExpressionParser.parse(raw)
    }

    public static func pattern(
        _ raw: String
    ) throws -> PathPattern {
        try expression(raw).pattern
    }
}

// import Parsing
// import Path

// public enum PathParse {
//     public static let expressionParser = PathExpressionParser()
//     public static let selectionExpressionParser = PathSelectionExpressionParser()

//     public static func expression(
//         _ raw: String
//     ) throws -> PathExpression {
//         try PathExpressionParser.parse(raw)
//     }

//     public static func selectionExpression(
//         _ raw: String
//     ) throws -> PathSelectionExpression {
//         try PathSelectionExpressionParser.parse(raw)
//     }

//     public static func pattern(
//         _ raw: String
//     ) throws -> PathPattern {
//         try expression(raw).pattern
//     }

//     public static func selection(
//         _ raw: String
//     ) throws -> PathSelection {
//         try selectionExpression(raw).selection
//     }
// }
