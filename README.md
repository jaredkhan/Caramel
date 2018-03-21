# Caramel

[![Build Status](https://travis-ci.org/jaredkhan/Caramel.svg?branch=master)](https://travis-ci.org/jaredkhan/Caramel)

A [program dependence graph](https://en.wikipedia.org/wiki/Program_Dependence_Graph) and [program slicer](https://en.wikipedia.org/wiki/Program_slicing) for the Swift programming language.

---
**This project is a work in progress from Oct 2017 - May 2018**

- [x] Parse data from `-ast-dump`
- [x] Implement a CFG
- [x] Implement a PDG
- [ ] Implement slicing algorithm over PDG
- [ ] Write usage docs

---

To download and run:

1. Make sure you have Swift installed
2. run `git clone https://github.com/jaredkhan/Caramel`
3. run `cd Caramel`
4. run `swift test` to run the test suite
5. run `swift run Caramel <file_path>` to run Caramel on a certain file