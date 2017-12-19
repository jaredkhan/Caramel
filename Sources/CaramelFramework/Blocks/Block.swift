public protocol Block {
  var offset: Int64 { get }
  var length: Int64 { get }

  func getCFG() -> CFG
}