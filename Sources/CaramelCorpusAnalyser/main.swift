import CaramelFramework
import SourceKittenFramework
import SwiftShell

if CommandLine.arguments.count > 1 {
  let filePath = CommandLine.arguments[1]
  // let structure = Structure(file: file)

  // dump(structure)
  
  print(functionLengths(filePath: filePath))
//  print(usesMutatingFunctions(filePath: filePath))
} else {
  print("error: no file given or file not recognised")
}
