import XCTest
@testable import BracketStructureParser

class BracketStructureParserTests: XCTestCase {
    func testSimpleNoQuotes() {
      XCTAssertEqual(
        try BracketStructure(string: "(branch hello (branch 2 (leaf 1) (leaf 3)) (leaf 5))"),
        BracketStructure.container([
          .text("branch"),
          .text("hello"),
          .container([
            .text("branch"),
            .text("2"),
            .container([
              .text("leaf"),
              .text("1")
            ]),
            .container([
              .text("leaf"),
              .text("3")
            ])
          ]),
          .container([
            .text("leaf"),
            .text("5")
          ])
        ])
      )
    }

    func testSimpleWithQuotes() {
      XCTAssertEqual(
        try BracketStructure(string: "(branch 'hello' (leaf 'world ') (branch 'goodbye (old friend)' (leaf 'hey') (leaf 'yo')))"),
        BracketStructure.container([
          .text("branch"),
          .text("'hello'"),
          .container([
            .text("leaf"),
            .text("'world '")
          ]),
          .container([
            .text("branch"),
            .text("'goodbye (old friend)'"),
            .container([
              .text("leaf"),
              .text("'hey'")
            ]),
            .container([
              .text("leaf"),
              .text("'yo'")
            ])
          ])
        ])
      )
    }

    func testAST() {
      XCTAssertEqual(
        try BracketStructure(string: 
          """
            (call_expr implicit type=\"Int\" location=func.swift:2:11 range=[func.swift:2:11 - line:2:11] nothrow arg_labels=_builtinIntegerLiteral:
              (constructor_ref_call_expr implicit type='(_MaxBuiltinIntegerType) -> Int' location=func.swift:2:11 range=[func.swift:2:11 - line:2:11] nothrow
                (declref_expr implicit type='(Int.Type) -> (_MaxBuiltinIntegerType) -> Int' location=func.swift:2:11 range=[func.swift:2:11 - line:2:11] decl=Swift.(file).Int.init(_builtinIntegerLiteral:) function_ref=single)
                (type_expr implicit type='Int.Type' location=func.swift:2:11 range=[func.swift:2:11 - line:2:11] typerepr='Int')))
          """
        ),
        BracketStructure.container([
          .text("call_expr"),
          .text("implicit"),
          .text("type=\"Int\""),
          .text("location=func.swift:2:11"),
          .text("range=[func.swift:2:11 - line:2:11]"),
          .text("nothrow"),
          .text("arg_labels=_builtinIntegerLiteral:"),
          .container([
            .text("constructor_ref_call_expr"),
            .text("implicit"),
            .text("type='(_MaxBuiltinIntegerType) -> Int'"),
            .text("location=func.swift:2:11"),
            .text("range=[func.swift:2:11 - line:2:11]"),
            .text("nothrow"),
            .container([
              .text("declref_expr"),
              .text("implicit"),
              .text("type='(Int.Type) -> (_MaxBuiltinIntegerType) -> Int'"),
              .text("location=func.swift:2:11"),
              .text("range=[func.swift:2:11 - line:2:11]"),
              .text("decl=Swift.(file).Int.init(_builtinIntegerLiteral:)"),
              .text("function_ref=single")
            ]),
            .container([
              .text("type_expr"),
              .text("implicit"),
              .text("type='Int.Type'"),
              .text("location=func.swift:2:11"),
              .text("range=[func.swift:2:11 - line:2:11]"),
              .text("typerepr='Int'")
            ])
          ])
        ])
      )
    }

    func testEmpty() {
      XCTAssertEqual(
        try BracketStructure(string: "   \n \t \r\n \n"),
        BracketStructure.container([])
      )
    }

    func testInvalid() {
      XCTAssertThrowsError(
        try BracketStructure(string: "(hello )goodbye)")
      )
    }

    func testNewLineBeforeClosingBracket() {
      XCTAssertEqual(
        try BracketStructure(string: """
          (top_level_code_decl
            (brace_stmt
              (pattern_binding_decl)
          ))
        """),
        BracketStructure.container([
          .text("top_level_code_decl"),
          .container([
            .text("brace_stmt"),
            .container([
              .text("pattern_binding_decl")
            ])
          ])
        ])
      )
    }

    static var allTests = [
      ("testSimpleNoQuotes", testSimpleNoQuotes),
      ("testSimpleWithQuotes", testSimpleWithQuotes),
      ("testAST", testAST),
      ("testEmpty", testEmpty),
      ("testInvalid", testInvalid),
      ("testNewLineBeforeClosingBracket", testNewLineBeforeClosingBracket)
    ]
}
