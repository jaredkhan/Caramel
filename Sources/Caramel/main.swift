import CaramelFramework
import Foundation
import SwiftShell

if CommandLine.arguments.count > 1 {
  let graphStartTime = NSDate().timeIntervalSince1970
  let cfg = PartialCFG(contentsOfFile: CommandLine.arguments[1])
  let completeCFG = try! CompleteCFG(cfg: cfg)
  let pdg = PDG(cfg: completeCFG)
  let graphBuildDuration = NSDate().timeIntervalSince1970 - graphStartTime
  print("Built full graph in: \(graphBuildDuration)")

  print("Enter criterion Line: ")
  let line = Int(readLine()!)!

  print("Enter criterion Column: ")
  let col = Int(readLine()!)!

  // outputGraph(dotFormat: pdg.graphVizDotFormat())
  let sliceStartTime = NSDate().timeIntervalSince1970
  printSlice(pdg.slice(line: line, column: col)!, ofFile: CommandLine.arguments[1])
  let sliceDuration = NSDate().timeIntervalSince1970 - sliceStartTime
  print("Found slice in: \(sliceDuration)")
} else {
  print("error: no file given")
}
