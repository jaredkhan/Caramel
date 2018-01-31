var myVar = 0

let (patternl, patternr) = (3, 2)

myVar = myVar + 1

if true {
  print("hello")
  myVar = 2
  let x = 2
} else if true {
  print("goodbye")
} else if true, true, true {
  print("Woah!")
}

for x in [1, 2, 3] {
  print(x)
  break
}

for x in 1 ... 3 {
  continue
}

while 1 > 2 {
  continue
}

while false {
  break
}

repeat {
  print("hi")
  if true { break }
} while 1 > 2

guard 2 > 1 else { fatalError("Dead") }

switch 1 {
  case 1, 3:
    print("one!")
    fallthrough
  case 2:
    break
  default: print("Nope")
}
