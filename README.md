# Caramel

[![Build Status](https://travis-ci.org/jaredkhan/Caramel.svg?branch=master)](https://travis-ci.org/jaredkhan/Caramel)

A [program dependence graph](https://en.wikipedia.org/wiki/Program_Dependence_Graph) and [program slicer](https://en.wikipedia.org/wiki/Program_slicing) for the Swift programming language.

---
**Caveats**

Caramel supports only the following language features: 

- Declaration of constants
- Declaration of variables
- for in statements
- guard statements (including optional binding)
- if statements (including optional binding)
- repeat while statements (including optional binding)
- switch statements
- while statements (including optional binding)
- Assignment expressions
- Binary operator expressions

Caramel is an intraprocedural slicer, it can only slice one function at a time.

Caramel does not work with mutating functions. It assumes assignments are only made at assignment statements.

Caramel is not designed to work with non-scalar values (such as arrays, structs, tuples) and can result in incorectness and/or imprecision in these cases.

---

To download and run:

1. Make sure you have Swift installed
2. run `git clone https://github.com/jaredkhan/Caramel`
3. run `cd Caramel`
4. run `swift test` to run the test suite
5. run `swift run Caramel <file_path>` to run Caramel on a certain file. You will be prompted for a line and column number and provided with a highlighted source code output.