import XCTest
import ParserDescription
import ParserDescriptionOperators
import ParserDescriptionCompiler
import ParserCombinators
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
        let tokenPattern = TokenPattern(condition:
            LabelCondition(label: "text", op: .isEqualTo, input: "foo")
                || LabelCondition(label: "text", op: .isEqualTo, input: "bar")
        )
        let pattern = tokenPattern.capture("token").rep(min: 1)

        let compiler = PatternCompiler<String>()
        let parser: Parser<Captures, String> = try compiler.compile(pattern: pattern)

        let reader = CollectionReader(collection: ["foo", "foo", "bar", "baz"])

        guard case .success(let captures, _) = parser.parse(reader) else {
            XCTFail("parsing should succeed")
            return
        }

        XCTAssertEqual(String(describing: captures.values),
                       String(describing: ["foo", "foo", "bar"]))
        XCTAssertEqual(String(describing: captures.entries.sorted { $0.key < $1.key }),
                       String(describing: [
                        (key: "token", value: [["foo"], ["foo"], ["bar"]])
                    ]))
    }
}
