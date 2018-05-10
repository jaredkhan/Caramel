let n = Int(readLine()!)!
var sum = 0
var product = 1

for i in 1 ..< n {
  sum += i
  product *= i
}

print(product)
print(sum)
