import Rainbow
import CaramelFramework

func printSlice(_ slice: Set<BasicBlock>, ofFile filePath: String) {
  // Slices do not overlap
  // Order them by startoffset
  var orderedSliceNodes = slice.sorted {
    let leftOffset = try! $0.range.start.offset()
    let rightOffset = try! $1.range.start.offset()
    return leftOffset > rightOffset
  }

  var result = ""

  // The offset of the next thing to print
  var currentCoveredOffset = 0
  while let nextSliceNode = orderedSliceNodes.popLast() {
    let nodeStartOffset = try! nextSliceNode.range.start.offset()
    let nodeEndOffset = try! nextSliceNode.range.end.offset()
    result += String(try! SnippetGrabber.get(
      filePath: filePath,
      startOffset: currentCoveredOffset,
      endOffset: nodeStartOffset
    )).lightBlack
    currentCoveredOffset = nodeStartOffset
    result += String(try! SnippetGrabber.get(
      filePath: filePath,
      startOffset: nodeStartOffset,
      endOffset: nodeEndOffset
    ))
    currentCoveredOffset = nodeEndOffset
  }

  print(result)
}