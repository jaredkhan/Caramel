import CaramelFramework

if CommandLine.arguments.count > 1 {

  let cfg = CFG(contentsOfFile: CommandLine.arguments[1])
  dump(cfg)
} else {
  print("error: no file given")
}
