import XCTest

extension ParserDescriptionTests {
    static let __allTests = [
        ("testCoding", testCoding),
        ("testCompilation", testCompilation),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ParserDescriptionTests.__allTests),
    ]
}
#endif
