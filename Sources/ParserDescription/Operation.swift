
public enum Operation: String, Codable {
    case isEqualTo = "="
    case isNotEqualTo = "!="
    case hasPrefix = "prefix"
    case matchesRegularExpression = "regex"
}
