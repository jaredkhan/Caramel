import CaramelFramework
import Foundation
import SwiftShell

if CommandLine.arguments.count > 1 {

  let cfg = CFG(contentsOfFile: CommandLine.arguments[1])
  let dotFormat = cfg.graphVizDotFormat()

  let task = Process()
  task.launchPath = "/usr/bin/env"
  task.arguments = ["dot", "-Tpng", "-o", "graph1.png"]

  let inputPipe = Pipe()
  let inputHandle = inputPipe.fileHandleForWriting
  inputHandle.write(dotFormat)
  inputHandle.closeFile()

  let pipe = Pipe()
  task.standardInput = inputPipe
  task.standardOutput = pipe
  task.standardError = pipe
  task.launch()

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  _ = String(data: data, encoding: .utf8)
  task.waitUntilExit()

  if task.terminationStatus == 0 {
    run("open", "graph1.png")
  } else {
    print("Couldn't write graph image")
  }
} else {
  print("error: no file given")
}
