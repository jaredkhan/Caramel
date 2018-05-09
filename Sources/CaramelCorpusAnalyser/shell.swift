import Foundation

/**
 Executes a shell command synchronously, returning the exit code
 
 - parameters:
 - args: The arguments to the shell command, starting with the command itself
 
 - returns:
 The output of the command and the exit code as a tuple
 
 Taken from: https://stackoverflow.com/a/31510860
 */
@discardableResult
public func shell(_ args: String...) -> (output: String? , exitCode: Int32) {
  let task = Process()
  task.launchPath = "/usr/bin/env"
  task.arguments = args
  
  let pipe = Pipe()
  task.standardOutput = pipe
  task.standardError = pipe
  task.launch()
  
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let output = String(data: data, encoding: .utf8)
  task.waitUntilExit()
  
  return (output, task.terminationStatus)
}
