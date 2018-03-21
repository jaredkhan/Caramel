struct Queue<T> {
  private var front: [T] = []
  private var back: [T] = []

  mutating func enqueue(_ item: T) {
    back.append(item)
  }

  mutating func dequeue() -> T? {
    // If front is empty, move the back
    // Take the last of the front
    if front.isEmpty {
      while !back.isEmpty {
        front.append(back.removeLast())
      }
    }

    return front.isEmpty ? nil : front.removeLast()
  }

  var isEmpty: Bool {
    return front.isEmpty && back.isEmpty
  }
}