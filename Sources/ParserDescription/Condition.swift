
public enum ConditionType: String, Codable {
    case label
    case and
    case or
    case not
}

public protocol _Condition: Codable {
    var type: ConditionType { get }
}

public protocol Condition: _Condition, Hashable {}


public indirect enum AnyCondition: Condition {

    public var type: ConditionType {
        return condition.type
    }

    case label(LabelCondition)
    case and(AndCondition)
    case or(OrCondition)
    case not(NotCondition)

    public var condition: _Condition {
        switch self {
        case let .label(condition):
            return condition
        case let .and(condition):
            return condition
        case let .or(condition):
            return condition
        case let .not(condition):
            return condition
        }
    }

    private enum CodingKeys: CodingKey {
        case type
    }

    public init<T: Condition>(_ condition: T) {
        switch condition {
        case let labelCondition as LabelCondition:
            self = .label(labelCondition)
        case let andCondition as AndCondition:
            self = .and(andCondition)
        case let orCondition as OrCondition:
            self = .or(orCondition)
        case let notCondition as NotCondition:
            self = .not(notCondition)
        case let anyCondition as AnyCondition:
            self = anyCondition
        default:
            fatalError("unsupported condition: \(condition)")
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ConditionType.self, forKey: .type)
        switch type {
        case .label:
            self = .label(try LabelCondition(from: decoder))
        case .and:
            self = .and(try AndCondition(from: decoder))
        case .or:
            self = .or(try OrCondition(from: decoder))
        case .not:
            self = .not(try NotCondition(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let condition = self.condition
        try container.encode(condition.type, forKey: .type)
        try condition.encode(to: encoder)
    }
}


extension Condition {

    public func or<T: Condition>(_ other: T) -> OrCondition {
        if let or = self as? OrCondition {
            var conditions = or.conditions
            conditions.append(AnyCondition(other))
            return OrCondition(conditions: conditions)
        } else {
            return OrCondition(conditions: [
                AnyCondition(self),
                AnyCondition(other)
            ])
        }
    }

    public func and<T: Condition>(_ other: T) -> AndCondition {
        if let seq = self as? AndCondition {
            var conditions = seq.conditions
            conditions.append(AnyCondition(other))
            return AndCondition(conditions: conditions)
        } else {
            return AndCondition(conditions: [
                AnyCondition(self),
                AnyCondition(other)
            ])
        }
    }
}


public struct AndCondition: Condition {

    public var type: ConditionType {
        return .and
    }

    public let conditions: [AnyCondition]

    private enum CodingKeys: CodingKey {
        case conditions
    }

    public init(conditions: [AnyCondition]) {
        self.conditions = conditions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conditions = try container.decode([AnyCondition].self, forKey: .conditions)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conditions, forKey: .conditions)
    }
}


public struct OrCondition: Condition {

    public var type: ConditionType {
        return .or
    }

    public let conditions: [AnyCondition]

    private enum CodingKeys: CodingKey {
        case conditions
    }

    public init(conditions: [AnyCondition]) {
        self.conditions = conditions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conditions = try container.decode([AnyCondition].self, forKey: .conditions)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conditions, forKey: .conditions)
    }
}


public struct NotCondition: Condition {

    public var type: ConditionType {
        return .not
    }

    public let condition: AnyCondition

    private enum CodingKeys: CodingKey {
        case condition
    }

    public init(condition: AnyCondition) {
        self.condition = condition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        condition = try container.decode(AnyCondition.self, forKey: .condition)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(condition, forKey: .condition)
    }
}


public struct LabelCondition: Condition {

    public var type: ConditionType {
        return .label
    }

    public let label: String
    public let op: Operation
    public let input: String

    public init(label: String, op: Operation, input: String) {
        self.label = label
        self.op = op
        self.input = input
    }
}
