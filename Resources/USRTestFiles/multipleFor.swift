for x in [1, 2, 3] {
  print(x)
}

for x in [4, 5, 6] {
  print(x)
}

if let x = Int("3") {
  print(x)
}

let x = "Hello, world"
print(x)

for x in ["a", "b", "c"] {
  print(x)
}

for _ in [1] {
  for x in [1, 2, 3] {
    print(x)
  }
}

if true {
  let x = "Hello, scope"
  print(x)
}

// Run the following commands:
/*
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=1:5 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=2:9 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=5:5 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=6:9 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=9:8 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=10:9 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=13:5 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=14:7 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=16:5 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=17:9 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=21:7 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=21:7 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
~/Developer/swift/swift-source/build/Ninja-RelWithDebInfoAssert/swift-macosx-x86_64/bin/sourcekitd-test -req=cursor -pos=28:9 ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift -- ~/Developer/swift/slicing/Caramel/Resources/USRTestFiles/multipleFor.swift
*/

// You should notice the USRs that they each give using SourceKit:
// s:11multipleFor1xL_Sivp
// s:11multipleFor1xL_Sivp
// s:11multipleFor1xL_Sivp
// s:11multipleFor1xL_Sivp
// s:11multipleFor1xL_Sivp
// s:11multipleFor1xL_Sivp
// s:11multipleFor1xSSvp
// s:11multipleFor1xSSvp
// s:11multipleFor1xL_SSvp
// s:11multipleFor1xL_SSvp
// s:11multipleFor1xL_Sivp
// s:11multipleFor1xL_SSvp
// i.e. uniqueness is only guaranteed up to the loop

// Using swift_ide_test the USRs given are:
// s:14swift_ide_test1xL_Sivp
// s:14swift_ide_test1xL_Sivp
// s:14swift_ide_test1xSSvp
// etc.
// i.e. also not unique, looks like the same resolution algorithm