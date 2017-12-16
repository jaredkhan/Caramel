import CaramelFramework
import SwiftShell

if CommandLine.arguments.count > 1 {
  let fileName = CommandLine.arguments[1]
  let astDump = run("/usr/bin/swiftc", "-dump-ast", fileName).stderror
  let astNode = try ASTNode(string: astDump)
  dump(astNode)
} else {
  print("error: no file given")
}
