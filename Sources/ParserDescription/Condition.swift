
public enum ConditionType: String, Codable {
    case label
    case and
    case or
    case not

    public var metatype: Condition.Type {
        switch self {
        case .label:
            return LabelCondition.self
        case .and:
            return AndCondition.self
        case .or:
            return OrCondition.self
        case .not:
            return NotCondition.self
        }
    }
}


public protocol Condition: Codable {

    static var conditionType: ConditionType { get }
}


extension Condition {

    public func or(_ other: Condition) -> OrCondition {
        if let or = self as? OrCondition {
            var conditions = or.conditions
            conditions.append(other)
            return OrCondition(conditions: conditions)
        } else {
            return OrCondition(conditions: [self, other])
        }
    }

    public func and(_ other: Condition) -> AndCondition {
        if let seq = self as? AndCondition {
            var conditions = seq.conditions
            conditions.append(other)
            return AndCondition(conditions: conditions)
        } else {
            return AndCondition(conditions: [self, other])
        }
    }
}


public struct TypedCondition: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public let condition: Condition

    public init(_ condition: Condition) {
        self.condition = condition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(ConditionType.self, forKey: .type)
        condition = try type.metatype.init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(type(of: condition).conditionType, forKey: .type)
        try condition.encode(to: encoder)
    }
}


public struct AndCondition: Condition {

    public static let conditionType: ConditionType = .and

    public let conditions: [Condition]

    private enum CodingKeys: CodingKey {
        case conditions
    }

    public init(conditions: [Condition]) {
        self.conditions = conditions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conditions = try container.decode([TypedCondition].self, forKey: .conditions)
            .map { $0.condition }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conditions.map(TypedCondition.init), forKey: .conditions)
    }
}


public struct OrCondition: Condition {

    public static let conditionType: ConditionType = .or

    public let conditions: [Condition]

    private enum CodingKeys: CodingKey {
        case conditions
    }

    public init(conditions: [Condition]) {
        self.conditions = conditions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conditions = try container.decode([TypedCondition].self, forKey: .conditions)
            .map { $0.condition }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conditions.map(TypedCondition.init), forKey: .conditions)
    }
}


public struct NotCondition: Condition {

    public static let conditionType: ConditionType = .not

    public let condition: Condition

    private enum CodingKeys: CodingKey {
        case condition
    }

    public init(condition: Condition) {
        self.condition = condition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        condition = try container.decode(TypedCondition.self, forKey: .condition).condition
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(TypedCondition(condition), forKey: .condition)
    }
}


public struct LabelCondition: Condition {

    public static let conditionType: ConditionType = .label

    public let label: String
    public let op: Operation
    public let input: String

    public init(label: String, op: Operation, input: String) {
        self.label = label
        self.op = op
        self.input = input
    }
}
