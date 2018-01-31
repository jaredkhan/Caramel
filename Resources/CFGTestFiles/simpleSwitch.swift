switch 1 {
  case 1, 3:
    print("one!")
    fallthrough
  case 2:
    break
  default: print("Nope")
}