import CaramelFramework
import Foundation
import SwiftShell

let fileName: String
if CommandLine.arguments.count >= 2 {
  fileName = CommandLine.arguments[1]
} else {
  fileName = "/Users/jared/Developer/swift/slicing/Caramel/Resources/SlicingTestFiles/mediumSliceable.swift"
}

let graphStartTime = NSDate().timeIntervalSince1970
let cfg = PartialCFG(contentsOfFile: fileName)
print("CFG Node count: \(cfg.nodes.count)")
print("CFG Edge count: \(cfg.edges.values.reduce(0, { $0 + $1.count }))")
let completeCFG = try! CompleteCFG(cfg: cfg)
let pdg = PDG(cfg: completeCFG)
print("PDG Node count: \(pdg.nodes.count)")
print("PDG Edge count: \(pdg.edges.values.reduce(0, { $0 + $1.count }))")
let graphBuildDuration = NSDate().timeIntervalSince1970 - graphStartTime
print("Built full graph in: \(graphBuildDuration)")
outputGraph(dotFormat: completeCFG.graphVizDotFormat())

print("Enter criterion Line: ")
let line = Int(readLine()!)!

print("Enter criterion Column: ")
let col = Int(readLine()!)!

print(completeCFG.graphVizDotFormat())

let sliceStartTime = NSDate().timeIntervalSince1970
printSlice(pdg.slice(line: line, column: col)!, ofFile: CommandLine.arguments[1])
let sliceDuration = NSDate().timeIntervalSince1970 - sliceStartTime
print("Found slice in: \(sliceDuration)")
