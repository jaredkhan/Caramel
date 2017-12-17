import CaramelFramework

if CommandLine.arguments.count > 1 {
  let block = try! structuralBlock(filePath: CommandLine.arguments[1])
  dump(block)
  // let astNode = try ASTNode(filePath: CommandLine.arguments[1])
  // dump(astNode.getAllNodeTypes())
} else {
  print("error: no file given")
}
