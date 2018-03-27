let n = Int(readLine()!)!
var result = 1
if n > 0 {
  for m in 1 ... n {
    result *= m
  }
}
print(result)
