import XCTest
@testable import CaramelFramework

class CaramelFrameworkTests: XCTestCase {
    func testAST() {
      XCTAssertEqual(
        try ASTNode(string: 
          """
            (call_expr implicit type=\"Int\" location=func.swift:2:11 range=[func.swift:2:11 - line:2:11] nothrow arg_labels=_builtinIntegerLiteral:
              (constructor_ref_call_expr implicit type='(_MaxBuiltinIntegerType) -> Int' location=func.swift:2:11 range=[func.swift:2:11 - line:2:11] nothrow
                (declref_expr implicit type='(Int.Type) -> (_MaxBuiltinIntegerType) -> Int' location=func.swift:2:11 range=[func.swift:2:11 - line:2:11] decl=Swift.(file).Int.init(_builtinIntegerLiteral:) function_ref=single)
                (type_expr implicit type='Int.Type' location=func.swift:2:11 range=[func.swift:2:11 - line:2:11] typerepr='Int')))
          """
        ),
        ASTNode(
          type: "call_expr",
          attributes: [
            "implicit",
            "type=\"Int\"",
            "location=func.swift:2:11",
            "range=[func.swift:2:11 - line:2:11]",
            "nothrow",
            "arg_labels=_builtinIntegerLiteral:"
          ],
          children: [
            ASTNode(
              type: "constructor_ref_call_expr",
              attributes: [
                "implicit",
                "type='(_MaxBuiltinIntegerType) -> Int'",
                "location=func.swift:2:11",
                "range=[func.swift:2:11 - line:2:11]",
                "nothrow"
              ],
              children: [
                ASTNode(
                  type: "declref_expr",
                  attributes: [
                    "implicit",
                    "type='(Int.Type) -> (_MaxBuiltinIntegerType) -> Int'",
                    "location=func.swift:2:11",
                    "range=[func.swift:2:11 - line:2:11]",
                    "decl=Swift.(file).Int.init(_builtinIntegerLiteral:)",
                    "function_ref=single"
                  ],
                  children: []
                ),
                ASTNode(
                  type: "type_expr",
                  attributes: [
                    "implicit",
                    "type='Int.Type'",
                    "location=func.swift:2:11",
                    "range=[func.swift:2:11 - line:2:11]",
                    "typerepr='Int'"
                  ],
                  children: []
                )
              ]
            )
          ]
        )
      )
    }

    func testRange() {
      XCTAssertEqual(
        ASTNode(
          type: "test_decl",
          attributes: [
            "nothing_here=000",
            "range=[test.swift:12:13 - line:14:15]"
          ],
          children: []
        ).range,
        SourceRange(
          fileName: "test.swift",
          range: 
            SourceFileLocation(
              line: 12,
              column: 13
            ) ... 
            SourceFileLocation(
              line: 14,
              column: 15
            )
        )
      )
    }
    static var allTests = [
        ("testAST", testAST),
        ("testRange", testRange)
    ]
}
