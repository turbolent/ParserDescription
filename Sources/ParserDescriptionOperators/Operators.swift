
import ParserDescription


public func && <T, U>(lhs: T, rhs: U) -> AndCondition
    where T: Condition, U: Condition
{
    return lhs.and(rhs)
}


public func || <T, U>(lhs: T, rhs: U) -> OrCondition
    where T: Condition, U: Condition
{
    return lhs.or(rhs)
}


infix operator ~ : ApplicativePrecedence


public func ~ <T, U>(lhs: T, rhs: U) -> SequencePattern
    where T: Pattern, U: Pattern
{
    return lhs.sequence(rhs)
}


public func || <T, U>(lhs: T, rhs: U) -> OrPattern
    where T: Pattern, U: Pattern
{
    return lhs.or(rhs)
}
