import CaramelFramework
import Foundation
import SwiftShell

if CommandLine.arguments.count > 1 {

  let cfg = CFG(contentsOfFile: CommandLine.arguments[1])

  // for node in cfg.nodes {
  //   print("REF")
  //   dump(node.references())
  //   print("DEF")
  //   dump(node.definitions())
  // }

  outputGraph(dotFormat: cfg.graphVizDotFormat())

} else {
  print("error: no file given")
}