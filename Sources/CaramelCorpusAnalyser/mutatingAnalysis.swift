import CaramelFramework
import SwiftShell

func usesMutatingFunctions(filePath: String) -> [Bool] {
//  try? runAndPrint("/usr/bin/swiftc", "-dump-ast", filePath)
  var astDump = shell("swiftc", "-dump-ast", "/Users/jared/Developer/swift/slicing/Caramel/Sources/CaramelFramework/CFGBuilder.swift").output ?? ""
  
  // First character should be (
  // If it isn't, scan up to the first \n(
  if !astDump.starts(with: "(") {
    guard let newLineIndex = astDump.range(of: "\n(")?.lowerBound else { fatalError("Couldn't find ast dump output") }
    let startPoint = astDump.index(after: newLineIndex)
    astDump = String(astDump[startPoint...])
  }
  
//  let astDump = run("/usr/bin/swiftc", "-dump-ast", "/Users/jared/Developer/swift/slicing/Caramel/Resources/SlicingTestFiles/multiplyAndAdd.swift").stderror
//  let astDump = run("/usr/bin/echo", "-dump-ast", filePath).stderror
  guard let astNode = try? ASTNode(string: astDump) else { fatalError("Couldn't parse ast dump") }
  dump(astNode)
//  return funcDecls(ast: astNode).map(containsInout)
  return [true]
}

// TODO: member_ref_expr in Classes could do anything

func containsInout(ast: ASTNode) -> Bool {
  return (ast.type == "inout_expr") || ast.children.reduce(false, { $0 || containsInout(ast: $1)})
}

func funcDecls(ast: ASTNode) -> [ASTNode] {
  let childDecls = ast.children.flatMap { funcDecls(ast: $0) }
  if ast.type == "func_decl" {
    return [ast] + childDecls
  }
  return childDecls
}
