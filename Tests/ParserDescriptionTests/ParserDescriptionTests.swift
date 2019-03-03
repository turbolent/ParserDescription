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

    public func isTokenLabel(
        _ label: String,
        matchingRegularExpression: NSRegularExpression
    ) -> Bool {
        return false
    }
}

final class ParserDescriptionTests: XCTestCase {

    func testCoding() throws {
        let tokenPattern =
            TokenPattern(condition:
                LabelCondition(label: "text", op: .equalTo, input: "foo")
                    || LabelCondition(label: "text", op: .equalTo, input: "bar")
            )
            ~ TokenPattern(condition:
                LabelCondition(label: "text", op: .equalTo, input: "baz")
            )

        if #available(OSX 10.13, *) {
            diffedAssertJSONEqual(
                """
                {
                  "type" : "sequence",
                  "patterns" : [
                    {
                      "type" : "token",
                      "condition" : {
                        "type" : "or",
                        "conditions" : [
                          {
                            "label" : "text",
                            "op" : "=",
                            "input" : "foo",
                            "type" : "label"
                          },
                          {
                            "label" : "text",
                            "op" : "=",
                            "input" : "bar",
                            "type" : "label"
                          }
                        ]
                      }
                    },
                    {
                      "type" : "token",
                      "condition" : {
                        "label" : "text",
                        "op" : "=",
                        "input" : "baz",
                        "type" : "label"
                      }
                    }
                  ]
                }
                """,
                TypedPattern(tokenPattern)
            )
        } else {
            // TODO
        }
    }

    func testCompilation() throws {
        let tokenPattern = TokenPattern(condition:
            LabelCondition(label: "text", op: .equalTo, input: "foo")
                || LabelCondition(label: "text", op: .equalTo, input: "bar")
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
