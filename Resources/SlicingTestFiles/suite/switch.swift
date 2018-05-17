let n = Int(readLine()!)!
var x = 1
var y = 1

for i in 1 ..< n {
  switch i {
    case 0...9: x += 1
    case 10...19: y += 1
    case 20...25: 
      x = y + 1
    default: x = 0
  }
}

print(x)
print(y)
