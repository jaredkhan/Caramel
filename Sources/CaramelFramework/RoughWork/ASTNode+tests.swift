/// Control Flow Graph
extension ASTNode {
  // Find `if_stmt`s
  public func findIfs() -> [ASTNode] {
    let childIfs = children.reduce([], { $0 + $1.findIfs() })
    if type == "if_stmt" {
      return [self] + childIfs
    } else {
      return childIfs
    }
  }
}

// extension ASTNode {
//   public func getBasicBlocks() -> [String] {
//     switch type {
//       case "top_level_code_decl", "source_file":
//         return children.reduce([], { $0 + $1.getBasicBlocks() })
//       case "pattern_binding_decl",
//       case "integer_literal_expr",
//       case "pattern_binding_decl",
//       case "paren_expr",
//       case "binary_expr",
//       case "call_expr",
//       case "tuple_expr",
//       case "brace_stmt",
//       case "dot_syntax_call_expr",
//       case "declref_expr",
//       case "erasure_expr",
//       case "constructor_ref_call_expr",
//       case 
//       case "var_decl",
//       case "string_literal_expr",
//       case "tuple_shuffle_expr",
//       case "pattern_named",
//       case "load_expr",
//       case "if_stmt",
//       case "type_expr"
//       default: // fail
//     }
//   }
// }

extension ASTNode {
  public func getAllNodeTypes() -> Set<String> {
    let types = Set<String>([type])
    let childTypes = children.map({ $0.getAllNodeTypes() }).reduce(Set<String>(), {$0.union($1)})
    return types.union(childTypes)
  }
  // public func checkSupported() -> Bool {
  //   let supportedNodeTypes = [
  //     "top_level_code_decl",
  //     "integer_literal_expr",
  //     "pattern_binding_decl",
  //     "paren_expr",
  //     "binary_expr",
  //     "call_expr",
  //     "tuple_expr",
  //     "brace_stmt",
  //     "dot_syntax_call_expr",
  //     "declref_expr",
  //     "erasure_expr",
  //     "constructor_ref_call_expr",
  //     "source_file",
  //     "var_decl",
  //     "string_literal_expr",
  //     "tuple_shuffle_expr",
  //     "pattern_named",
  //     "load_expr",
  //     "if_stmt",
  //     "type_expr"
  //   ]
  // }
}
