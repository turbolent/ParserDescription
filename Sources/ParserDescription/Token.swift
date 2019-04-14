
import Foundation


public protocol Token {

    func isTokenLabel(
        _ label: String,
        equalTo conditionInput: String
    ) -> Bool

    func doesTokenLabel(
        _ label: String,
        havePrefix conditionInput: String
    ) -> Bool

    func isTokenLabel(
        _ label: String,
        matchingRegularExpression regularExpression: NSRegularExpression
    ) -> Bool
}


public struct UnsupportedConditionError: Error {
    public let condition: _Condition
}


extension UnsupportedConditionError: LocalizedError {
    public var errorDescription: String? {
        return "Unsupported condition: \(condition)"
    }
}


public extension _Condition {

    func compile() throws -> (Token) -> Bool {
        switch self {
        case let condition as AndCondition:
            return try condition.compile()
        case let condition as OrCondition:
            return try condition.compile()
        case let condition as NotCondition:
            return try condition.compile()
        case let condition as LabelCondition:
            return try condition.compile()
        case let condition as AnyCondition:
            return try condition.condition.compile()
        default:
            throw UnsupportedConditionError(condition: self)
        }
    }
}


public extension AndCondition {

    func compile() throws -> (Token) -> Bool {
        let compiledConditions = try conditions.map { try $0.compile() }
        return { token in
            compiledConditions.allSatisfy { compiledCondition in
                compiledCondition(token)
            }
        }
    }
}


public extension OrCondition {

    func compile() throws -> (Token) -> Bool {
        let compiledConditions = try conditions.map { try $0.compile() }
        return { token in
            let match = compiledConditions.first { compiledCondition in
                compiledCondition(token)
            }
            return match != nil
        }
    }
}


public extension NotCondition {

    func compile() throws -> (Token) -> Bool {
        let compiledCondition = try condition.compile()
        return { token in
            !compiledCondition(token)
        }
    }
}


public extension LabelCondition {

    func compile() throws -> (Token) -> Bool {
        switch op {
        case .isEqualTo:
            return { [label, input] token in
                token.isTokenLabel(label, equalTo: input)
            }
        case .isNotEqualTo:
            return { [label, input] token in
                !token.isTokenLabel(label, equalTo: input)
            }
        case .matchesRegularExpression:
            let expression = try NSRegularExpression(pattern: input, options: [])
            return { [label] token in
                token.isTokenLabel(label, matchingRegularExpression: expression)
            }
        case .hasPrefix:
            return { [label, input] token in
                token.doesTokenLabel(label, havePrefix: input)
            }
        }
    }
}
