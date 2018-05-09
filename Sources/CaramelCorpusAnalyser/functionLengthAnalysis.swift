import CaramelFramework
import AST
import Parser
import Sema
import Source
import SourceKittenFramework

func functionLengths(filePath: String) -> [Int] {
  guard let sourceFile = try? SourceReader.read(at: filePath) else { fatalError("Couldn't read \(filePath)") }
  let parser = Parser(source: sourceFile)
  guard let topLevelDecl = try? parser.parse() else { fatalError("Couldn't parse \(filePath)") }
  
  // Nested expressions need to be folded explicitly
  let seqExprFolding = SequenceExpressionFolding()
  seqExprFolding.fold([topLevelDecl])
  
  let funcLengthVisitor = FunctionLengthVisitor()
  guard let _ = try? funcLengthVisitor.traverse(topLevelDecl) else { fatalError("Couldn't traverse") }
  return funcLengthVisitor.lengths
}

class FunctionLengthVisitor: ASTVisitor {
  public var lengths: [Int] = []
  public func visit(_ decl: FunctionDeclaration) throws -> Bool {
    // Add the length of this function to the lengths
    if let length = decl.body?.statements.count {
      lengths.append(length)
    }
    return true
  }
}
