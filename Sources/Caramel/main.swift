import CaramelFramework


if CommandLine.arguments.count > 1 {
  let astNode = try ASTNode(filePath: CommandLine.arguments[1])
  dump(astNode)
} else {
  print("error: no file given")
}
