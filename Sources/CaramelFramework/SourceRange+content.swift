import Source
extension SourceRange {
  /// Get the substring corresponding to this SourceRange
  public func content() throws -> Substring {
    return try SnippetGrabber.get(
      filePath: start.identifier,
      startOffset: try start.offset(),
      endOffset: try end.offset()
    )
  }
}