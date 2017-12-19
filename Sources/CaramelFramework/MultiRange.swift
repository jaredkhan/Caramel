/// A range that can have chunks added to and removed from it
public struct MultiRange<C: Comparable> {
  private struct Inclusion {
    let range: ClosedRange<C>
    let type: InclusionType
  }

  private enum InclusionType {
    case inclusion
    case exclusion
  }

  private var ranges: [Inclusion] = []

  /// Whether the multirange contains the given value
  public func contains(_ elem: C) -> Bool {
    if let firstInclusion = ranges.reversed().first(where: { $0.range.contains(elem) }) {
      switch firstInclusion.type {
        case .inclusion: return true
        case .exclusion: return false
      }
    }
    // Default to false 
    return false
  }

  /// Create a multirange that contains the same values as the given range
  public init(range: ClosedRange<C>) {
    ranges = [Inclusion(range: range, type: .inclusion)]
  }

  /// Remove the given range of values from the multirange
  public mutating func subtract(_ otherRange: ClosedRange<C>) {
    ranges.append(Inclusion(range: otherRange, type: .exclusion))
  }

  /// Add the given range of values from the multirange
  public mutating func formUnion(_ otherRange: ClosedRange<C>) {
    ranges.append(Inclusion(range: otherRange, type: .inclusion))
  }
}