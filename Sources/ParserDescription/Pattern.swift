
public enum PatternType: String, Codable {
    case token
    case sequence
    case repetition
    case or
    case capture

    public var type: Pattern.Type {
        switch self {
        case .token:
            return TokenPattern.self
        case .sequence:
            return SequencePattern.self
        case .repetition:
            return RepetitionPattern.self
        case .or:
            return OrPattern.self
        case .capture:
            return CapturePattern.self
        }
    }
}


public protocol Pattern: Codable {

    static var patternType: PatternType { get }
}


extension Pattern {

    public func or(_ other: Pattern) -> OrPattern {
        if let or = self as? OrPattern {
            var pattterns = or.patterns
            pattterns.append(other)
            return OrPattern(patterns: pattterns)
        } else {
            return OrPattern(patterns: [self, other])
        }
    }

    public func sequence(_ other: Pattern) -> SequencePattern {
        if let seq = self as? SequencePattern {
            var pattterns = seq.patterns
            pattterns.append(other)
            return SequencePattern(patterns: pattterns)
        } else {
            return SequencePattern(patterns: [self, other])
        }
    }

    public func capture(_ name: String) -> CapturePattern {
        return CapturePattern(pattern: self, name: name)
    }

    public func rep(min: Int? = nil, max: Int? = nil) -> RepetitionPattern {
        return RepetitionPattern(pattern: self, min: min, max: max)
    }
}


public struct TypedPattern: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public let pattern: Pattern

    public init(_ pattern: Pattern) {
        self.pattern = pattern
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(PatternType.self, forKey: .type)
        pattern = try type.type.init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(type(of: pattern).patternType, forKey: .type)
        try pattern.encode(to: encoder)
    }
}


public struct SequencePattern: Pattern {

    public static let patternType: PatternType = .sequence

    public let patterns: [Pattern]

    private enum CodingKeys: CodingKey {
        case patterns
    }

    public init(patterns: [Pattern]) {
        self.patterns = patterns
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patterns = try container.decode([TypedPattern].self, forKey: .patterns)
            .map { $0.pattern }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(patterns.map(TypedPattern.init), forKey: .patterns)
    }
}


public struct OrPattern: Pattern {

    public static let patternType = PatternType.or

    public let patterns: [Pattern]

    private enum CodingKeys: CodingKey {
        case patterns
    }

    public init(patterns: [Pattern]) {
        self.patterns = patterns
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patterns = try container.decode([TypedPattern].self, forKey: .patterns)
            .map { $0.pattern }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(patterns.map(TypedPattern.init), forKey: .patterns)
    }
}


public struct TokenPattern: Pattern {

    public static let patternType: PatternType = .token

    private enum CodingKeys: CodingKey {
        case condition
    }

    public let condition: Condition?

    public init(condition: Condition?) {
        self.condition = condition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        condition = try container.decode(TypedCondition.self, forKey: .condition).condition
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(condition.map(TypedCondition.init), forKey: .condition)
    }
}


public struct CapturePattern: Pattern {

    public static let patternType: PatternType = .capture

    public let name: String
    public let pattern: Pattern

    private enum CodingKeys: CodingKey {
        case name
        case pattern
    }

    public init(pattern: Pattern, name: String) {
        self.pattern = pattern
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        pattern = try container.decode(TypedPattern.self, forKey: .pattern).pattern

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(TypedPattern(pattern), forKey: .pattern)
    }
}


public struct RepetitionPattern: Pattern {

    public static let patternType: PatternType = .repetition

    public let pattern: Pattern
    public let min: Int?
    public let max: Int?

    private enum CodingKeys: CodingKey {
        case pattern
        case min
        case max
    }

    public init(pattern: Pattern, min: Int?, max: Int?) {
        self.pattern = pattern
        self.min = min
        self.max = max
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pattern = try container.decode(TypedPattern.self, forKey: .pattern).pattern
        min = try container.decodeIfPresent(Int.self, forKey: .min)
        max = try container.decodeIfPresent(Int.self, forKey: .max)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(TypedPattern(pattern), forKey: .pattern)
        try container.encodeIfPresent(min, forKey: .min)
        try container.encodeIfPresent(max, forKey: .max)
    }
}
