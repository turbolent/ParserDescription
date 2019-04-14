import XCTest
import ParserDescription
import ParserDescriptionOperators
import DiffedAssertEqual


extension String: Token {

    public func isTokenLabel(_ label: String, equalTo conditionInput: String) -> Bool {
        return label == "text"
            && self == conditionInput
    }

    public func doesTokenLabel(_ label: String, havePrefix prefix: String) -> Bool {
        return label == "text"
            && self.starts(with: prefix)
    }

    public func isTokenLabel(
        _ label: String,
        matchingRegularExpression: NSRegularExpression
    ) -> Bool {
        return false
    }
}


@available(OSX 10.13, *)
final class ParserDescriptionTests: XCTestCase {

    static let fileURL = URL(fileURLWithPath: #file)

    private func loadFixture(path: String) throws -> Data {
        let url = URL(
            fileURLWithPath: path,
            relativeTo: ParserDescriptionTests.fileURL
        )
        return try Data(contentsOf: url)
    }

    func testCoding() throws {
        let tokenPattern =
            TokenPattern(condition:
                LabelCondition(label: "text", op: .isEqualTo, input: "foo")
                    || LabelCondition(label: "text", op: .isEqualTo, input: "bar")
            )
            ~ TokenPattern(condition:
                LabelCondition(label: "text", op: .isEqualTo, input: "baz")
        )

        diffedAssertJSONEqual(
            String(data: try loadFixture(path: "pattern.json"), encoding: .utf8)!,
            AnyPattern(tokenPattern)
        )
    }

    func testCompilation() throws {
        let condition =
            LabelCondition(label: "text", op: .isEqualTo, input: "foo")
                || LabelCondition(label: "text", op: .isEqualTo, input: "bar")

        let predicate = try condition.compile()

        XCTAssertTrue(predicate("foo"))
        XCTAssertTrue(predicate("bar"))
        XCTAssertFalse(predicate("baz"))
    }
}
