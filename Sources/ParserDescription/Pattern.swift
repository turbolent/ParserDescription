
public enum PatternType: String, Codable {
    case token
    case sequence
    case repetition
    case or
    case capture
}

public protocol _Pattern: Codable {
    var type: PatternType { get }
}

public protocol Pattern: _Pattern, Hashable {}


public indirect enum AnyPattern: Pattern {
    public var type: PatternType {
        return pattern.type
    }

    private enum CodingKeys: CodingKey {
        case type
    }

    case token(TokenPattern)
    case sequence(SequencePattern)
    case repetition(RepetitionPattern)
    case or(OrPattern)
    case capture(CapturePattern)

    public var pattern: _Pattern {
        switch self {
        case let .token(pattern):
            return pattern
        case let .sequence(pattern):
            return pattern
        case let .repetition(pattern):
            return pattern
        case let .or(pattern):
            return pattern
        case let .capture(pattern):
            return pattern
        }
    }


    public init<T: Pattern>(_ pattern: T) {
        switch pattern {
        case let tokenPattern as TokenPattern:
            self = .token(tokenPattern)
        case let sequencePattern as SequencePattern:
            self = .sequence(sequencePattern)
        case let repetitionPattern as RepetitionPattern:
            self = .repetition(repetitionPattern)
        case let orPattern as OrPattern:
            self = .or(orPattern)
        case let capturePattern as CapturePattern:
            self = .capture(capturePattern)
        case let anyPattern as AnyPattern:
            self = anyPattern
        default:
            fatalError("unsupported pattern: \(pattern)")
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(PatternType.self, forKey: .type)
        switch type {
        case .token:
            self = .token(try TokenPattern(from: decoder))
        case .sequence:
            self = .sequence(try SequencePattern(from: decoder))
        case .repetition:
            self = .repetition(try RepetitionPattern(from: decoder))
        case .or:
            self = .or(try OrPattern(from: decoder))
        case .capture:
            self = .capture(try CapturePattern(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let pattern = self.pattern
        try container.encode(pattern.type, forKey: .type)
        try pattern.encode(to: encoder)
    }
}

extension Pattern {

    public func or<T: Pattern>(_ other: T) -> OrPattern {
        if let or = self as? OrPattern {
            var patterns = or.patterns
            patterns.append(AnyPattern(other))
            return OrPattern(patterns: patterns)
        } else {
            return OrPattern(patterns: [
                AnyPattern(self),
                AnyPattern(other)
            ])
        }
    }

    public func sequence<T: Pattern>(_ other: T) -> SequencePattern {
        if let seq = self as? SequencePattern {
            var patterns = seq.patterns
            patterns.append(AnyPattern(other))
            return SequencePattern(patterns: patterns)
        } else {
            return SequencePattern(patterns: [
                AnyPattern(self),
                AnyPattern(other)
            ])
        }
    }

    public func capture(_ name: String) -> CapturePattern {
        return CapturePattern(pattern: AnyPattern(self), name: name)
    }

    public func rep(min: Int, max: Int? = nil) -> RepetitionPattern {
        return RepetitionPattern(pattern: AnyPattern(self), min: min, max: max)
    }

    public func opt() -> RepetitionPattern {
        return rep(min: 0, max: 1)
    }

    public func zeroOrMore() -> RepetitionPattern {
        return rep(min: 0)
    }

    public func oneOrMore() -> RepetitionPattern {
        return rep(min: 1)
    }
}


public struct SequencePattern: Pattern {

    public var type: PatternType {
        return .sequence
    }

    public let patterns: [AnyPattern]

    private enum CodingKeys: CodingKey {
        case patterns
    }

    public init(patterns: [AnyPattern]) {
        self.patterns = patterns
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patterns = try container.decode([AnyPattern].self, forKey: .patterns)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(patterns, forKey: .patterns)
    }
}


public struct OrPattern: Pattern {

    public var type: PatternType {
        return .or
    }

    public let patterns: [AnyPattern]

    private enum CodingKeys: CodingKey {
        case patterns
    }

    public init(patterns: [AnyPattern]) {
        self.patterns = patterns
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patterns = try container.decode([AnyPattern].self, forKey: .patterns)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(patterns, forKey: .patterns)
    }
}


public struct TokenPattern: Pattern {

    public var type: PatternType {
        return .token
    }

    private enum CodingKeys: CodingKey {
        case condition
    }

    public let condition: AnyCondition?

    public init(condition: AnyCondition?) {
        self.condition = condition
    }

    public init<T: Condition>(condition: T?) {
        self.init(condition: condition.map(AnyCondition.init))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        condition = try container.decodeIfPresent(AnyCondition.self, forKey: .condition)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(condition, forKey: .condition)
    }
}


public struct CapturePattern: Pattern {

    public var type: PatternType {
        return .capture
    }

    public let name: String
    public let pattern: AnyPattern

    private enum CodingKeys: CodingKey {
        case name
        case pattern
    }

    public init(pattern: AnyPattern, name: String) {
        self.pattern = pattern
        self.name = name
    }

    public init<T: Pattern>(pattern: T, name: String) {
        self.init(pattern: AnyPattern(pattern), name: name)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        pattern = try container.decode(AnyPattern.self, forKey: .pattern)

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(pattern, forKey: .pattern)
    }
}


public struct RepetitionPattern: Pattern {

    public var type: PatternType {
        return .repetition
    }

    public let pattern: AnyPattern
    public let min: Int
    public let max: Int?

    private enum CodingKeys: CodingKey {
        case pattern
        case min
        case max
    }

    public init(pattern: AnyPattern, min: Int, max: Int?) {
        self.pattern = pattern
        self.min = min
        self.max = max
    }

    public init<T: Pattern>(pattern: T, min: Int, max: Int?) {
        self.init(pattern: AnyPattern(pattern), min: min, max: max)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pattern = try container.decode(AnyPattern.self, forKey: .pattern)
        min = try container.decode(Int.self, forKey: .min)
        max = try container.decodeIfPresent(Int.self, forKey: .max)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pattern, forKey: .pattern)
        try container.encode(min, forKey: .min)
        try container.encodeIfPresent(max, forKey: .max)
    }
}
