
import Foundation
import ParserDescription
import ParserCombinators


internal extension Parser {

    func captured() -> Parser<Captures, Element> {
        return map { Captures(value: $0) }
    }
}

public typealias Pattern = ParserDescription.Pattern

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

public struct PatternCompiler<Token> where Token: ParserDescriptionCompiler.Token  {

    public enum Error: Swift.Error {
        case unsupportedPattern(Pattern)
        case unsupportedCondition(Condition)
    }

    public init() {}

    public func compile(pattern: Pattern) throws -> Parser<Captures, Token> {
        switch pattern {
        case let pattern as SequencePattern:
            return try compile(pattern: pattern)
        case let pattern as OrPattern:
            return try compile(pattern: pattern)
        case let pattern as RepetitionPattern:
            return try compile(pattern: pattern)
        case let pattern as CapturePattern:
            return try compile(pattern: pattern)
        case let pattern as TokenPattern:
            return try compile(pattern: pattern)
        default:
            throw Error.unsupportedPattern(pattern)
        }
    }

    public func compile(pattern: SequencePattern) throws -> Parser<Captures, Token> {
        return try pattern.patterns
            .map(compile)
            .reduce(success(Captures.empty)) { $0.seq($1) }
    }

    public func compile(pattern: OrPattern) throws -> Parser<Captures, Token> {
        return try pattern.patterns
            .map(compile)
            .reduce(success(Captures.empty)) { $0.or($1) }
    }

    public func compile(pattern: RepetitionPattern) throws -> Parser<Captures, Token> {
        return try compile(pattern: pattern.pattern)
            .rep(min: pattern.min ?? 0,
                 max: pattern.max)
    }

    public func compile(pattern: CapturePattern) throws -> Parser<Captures, Token> {
        return try compile(pattern: pattern.pattern)
            .capture(pattern.name)
    }

    public func compile(pattern: TokenPattern) throws -> Parser<Captures, Token> {
        guard let condition = pattern.condition else {
            return accept().captured()
        }

        let predicate = try compile(condition: condition)
        return acceptIf(errorMessageSupplier: { [condition] token in
                            "token \(token) does not match condition \(condition)"
                        },
                        predicate)
            .captured()
    }

    public func compile(condition: Condition) throws -> (Token) -> Bool {
        switch condition {
        case let condition as AndCondition:
            return try compile(condition: condition)
        case let condition as OrCondition:
            return try compile(condition: condition)
        case let condition as NotCondition:
            return try compile(condition: condition)
        case let condition as LabelCondition:
            return try compile(condition: condition)
        default:
            throw Error.unsupportedCondition(condition)
        }
    }

    public func compile(condition: AndCondition) throws -> (Token) -> Bool {
        let compiledConditions = try condition.conditions.map(compile)
        return { token in
            compiledConditions.allSatisfy { compiledCondition in
                compiledCondition(token)
            }
        }
    }

    public func compile(condition: OrCondition) throws -> (Token) -> Bool {
        let compiledConditions = try condition.conditions.map(compile)
        return { token in
            let match = compiledConditions.first { compiledCondition in
                compiledCondition(token)
            }
            return match != nil
        }
    }

    public func compile(condition: NotCondition) throws -> (Token) -> Bool {
        let compiledCondition = try compile(condition: condition.condition)
        return { token in
            !compiledCondition(token)
        }
    }

    public func compile(condition: LabelCondition) throws -> (Token) -> Bool {
        switch condition.op {
        case .isEqualTo:
            return {
                $0.isTokenLabel(condition.label, equalTo: condition.input)
            }
        case .isNotEqualTo:
            return {
                !$0.isTokenLabel(condition.label, equalTo: condition.input)
            }
        case .matchesRegularExpression:
            let expression = try NSRegularExpression(pattern: condition.input, options: [])
            return {
                $0.isTokenLabel(condition.label, matchingRegularExpression: expression)
            }
        case .hasPrefix:
            return {
                $0.doesTokenLabel(condition.label, havePrefix: condition.input)
            }
        }
    }
}
