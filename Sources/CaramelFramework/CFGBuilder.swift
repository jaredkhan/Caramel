import AST
import Source
import Foundation

func getCFG(_ decl: TopLevelDeclaration) -> PartialCFG {
  return getCFG(decl.statements)
}

func getCFG(_ block: CodeBlock) -> PartialCFG {
  return getCFG(block.statements)
}

func getCFG(_ statements: [Statement]) -> PartialCFG {
  return PartialCFG(
    chainingCFGs: statements.map { getCFG($0) },
    withContext: { currentCfg, nextCfg in 
      [
        // For each cfg: if it's not the last, point it to the next one,
        // otherwise point it to passiveNext
        .passiveNext: nextCfg?.entryPoint ?? .passiveNext
      ]
    }
  )
}

func getCFG(_ stmt: Statement) -> PartialCFG {
  // Check if declaration
  // Check type of statement
  switch stmt {
    case let n as ConstantDeclaration: 
      let node = Node(range: n.sourceRange, type: .expression)
      return PartialCFG(
        nodes: [node],
        edges: [node: [.passiveNext]],
        entryPoint: .node(node)
      )
    case let n as VariableDeclaration: 
      let node = Node(range: n.sourceRange, type: .expression)
      return PartialCFG(
        nodes: [node],
        edges: [node: [.passiveNext]],
        entryPoint: .node(node)
      )
    case let n as BreakStatement: 
      let node = Node(range: n.sourceRange, type: .breakStatement)
      return PartialCFG(
        nodes: [node],
        edges: [node: [.breakStatement]],
        entryPoint: .node(node)
      )
    case let n as ContinueStatement: 
      let node = Node(range: n.sourceRange, type: .continueStatement)
      return PartialCFG(
        nodes: [node],
        edges: [node: [.continueStatement]],
        entryPoint: .node(node)
      )
    // case let n as DeferStatement: 
    //   let node = Node(range: n.sourceRange, type: .breakStatement)
    //   return PartialCFG(
    //     nodes: [node],
    //     edges: [node: [.breakStatement]],
    //     entryPoint: .node(node)
    //   )
    case let n as FallthroughStatement: 
      let node = Node(range: n.sourceRange, type: .fallthroughStatement)
      return PartialCFG(
        nodes: [node],
        edges: [node: [.switchFallthrough]],
        entryPoint: .node(node)
      )
    case let n as ImportDeclaration:
      let node = Node(range: n.sourceRange, type: .declaration)
      return PartialCFG(
        nodes: [node],
        edges: [node: [.passiveNext]],
        entryPoint: .node(node)
      )
    case let n as ExtensionDeclaration:
      let memberCFGs = n.members.map { (member: ExtensionDeclaration.Member) -> PartialCFG in 
        switch member {
          case .declaration(let d): return getCFG(d)
          case .compilerControl(let c): return getCFG(c)
        }
      }
      return PartialCFG(
        chainingCFGs: memberCFGs,
        withContext: { (currentCfg: PartialCFG, nextCfg: PartialCFG?) in
          [
            .passiveNext: nextCfg?.entryPoint ?? .passiveNext
          ]
        }
      )
    case let n as FunctionDeclaration:
      guard let body = n.body else { fatalError("Functions must have bodies") }
      // Hack - the range of the signature is the range from the start of the function to the start of the body
      let signatureNode = Node(
        range: SourceRange(
          start: n.sourceRange.start,
          end: body.sourceRange.start
        ),
        type: .functionSignature
      )
      let bodyCFG = getCFG(body).applying(context: [
        .returnStatement: .passiveNext
      ])
      return PartialCFG(
        nodes: [signatureNode],
        edges: [signatureNode: [bodyCFG.entryPoint]],
        entryPoint: .node(signatureNode)
      ).merging(with: bodyCFG)
    case let n as ReturnStatement:
      let node = Node(range: n.sourceRange, type: .returnStatement)
      return PartialCFG(
        nodes: [node],
        edges: [node: [.returnStatement]],
        entryPoint: .node(node)
      )
    case let n as ForInStatement: 
      // The control flow for a for in loop goes as follows:
      // - Evalute collection,
      // - Match a value from collection with the pattern,
      // - If can assign to the pattern, enter the block, otherwise continue
      // - Resolve any `break` or `continue` appropriately
      // - When reach the end of the block, go back to the pattern
      let sequenceUSR = UUID().uuidString
      let collectionNode = getNode(n.collection)
      collectionNode.artificialDefinitions.insert(sequenceUSR)
      let patternNode = getNode(n.item.matchingPattern)
      patternNode.artificialReferences.insert(sequenceUSR)

      let collectionCFG = PartialCFG(
        nodes: [collectionNode],
        edges: [collectionNode: [.passiveNext]],
        entryPoint: .node(collectionNode)
      )
      
      var bodyCFG = getCFG(n.codeBlock)

      let patternCFG = PartialCFG(
        nodes: [patternNode],
        edges: [patternNode: [.patternMatch, .patternNotMatch]],
        entryPoint: .node(patternNode)
      ).applying(context: [
        .patternMatch: bodyCFG.entryPoint,
        .patternNotMatch: .passiveNext
      ])

      bodyCFG = bodyCFG.applying(context: [
        .continueStatement: patternCFG.entryPoint,
        .passiveNext: patternCFG.entryPoint,
        .breakStatement: .passiveNext
      ])

      return collectionCFG.applying(
        context: [
          .passiveNext: patternCFG.entryPoint
        ]
      ).merging(with: patternCFG, bodyCFG)
    case let n as GuardStatement: 
      // The control flow for a guard statements goes as follows:
      // - Evaluate each condition in turn
      // - If encounter a condition that does not hold, enter else block immediately
      // - Otherwise continue
      let elseCFG = getCFG(n.codeBlock).applying(context: [
        .passiveNext: nil // You cannot leave a guards else condition passively
        // TODO: What exit mechanisms can a guard use?
      ])
      let conditionChainCFG = getCFG(n.conditionList)

      return conditionChainCFG.applying(context: [
        .conditionHold: .passiveNext,
        .conditionFail: elseCFG.entryPoint
      ]).merging(with: elseCFG)
    case let n as IfStatement: 
      // The control flow for an if statements goes as follows:
      // - Evaluate each condition in turn
      // - If encounter a condition that does not hold, enter else block immediately
      // - Otherwise continue
      // "You can’t use an unlabeled break statement to break out of an if statement."
      let bodyCFG = getCFG(n.codeBlock)
      let elseCFG = n.elseClause.map(getCFG) ?? PartialCFG.empty
      let conditionChainCFG = getCFG(n.conditionList)

      return conditionChainCFG.applying(context: [
        .conditionHold: bodyCFG.entryPoint,
        .conditionFail: elseCFG.entryPoint
      ]).merging(with: bodyCFG, elseCFG)
    case let n as RepeatWhileStatement: 
      // The control flow of a repeat while statement is as follows: 
      // - Execute the body
      // - Route passiveNext to the conditionChain
      // - Route condition failure to passiveNext
      // - Route condition success back to body

      let conditionCFG = getCFG(
        Condition.expression(n.conditionExpression)
      )

      let bodyCFG = getCFG(n.codeBlock).applying(context: [
        .passiveNext: conditionCFG.entryPoint,
        .continueStatement: conditionCFG.entryPoint,
        .breakStatement: .passiveNext
      ])

      return bodyCFG.merging(with: conditionCFG.applying(context: [
        .conditionHold: bodyCFG.entryPoint,
        .conditionFail: .passiveNext
      ]))
    case let n as SwitchStatement: 
      let subject = getNode(n.expression)
      let subjectUSR = UUID().uuidString
      subject.artificialDefinitions.insert(subjectUSR)
      
      // All patterns within need to be data dependent on the subject

      // get pattern chains and bodies
      var cases = n.cases.map {(
        patternChainCFG: getPatternChainCFG($0, subjectUSR: subjectUSR),
        bodyCFG: getBodyCFG($0)
      )}

      for index in stride(from: cases.count - 1, through: 0, by: -1) {
        // Resolve pattern matches
        cases[index].patternChainCFG.apply(context: [
          .patternMatch: cases[index].bodyCFG.entryPoint,
          .patternNotMatch: (index + 1 < cases.count) ?
            cases[index + 1].patternChainCFG.entryPoint :
            nil // Switches are exhaustive, this case should never be hit
        ])

        // Resolve fallthroughs
        cases[index].bodyCFG.apply(context: [
          // Propagate fallthroughs in the last case
          .switchFallthrough: (index + 1 < cases.count) ?
            cases[index + 1].bodyCFG.entryPoint : .switchFallthrough
        ])
      }

      return PartialCFG(
        nodes: [subject],
        edges: [
          subject: [cases[0].patternChainCFG.entryPoint]
        ],
        entryPoint: .node(subject)
      ).merging(with: cases.map { $0.patternChainCFG } + cases.map { $0.bodyCFG } )
    case let n as WhileStatement: 
      let conditionListCFG = getCFG(n.conditionList)

      // condition either leads to body or passivenext

      let bodyCFG = getCFG(n.codeBlock).applying(context: [
        .passiveNext: conditionListCFG.entryPoint,
        .continueStatement: conditionListCFG.entryPoint,
        .breakStatement: .passiveNext
      ])

      return conditionListCFG.applying(context: [
        .conditionHold: bodyCFG.entryPoint,
        .conditionFail: .passiveNext
      ]).merging(with: bodyCFG)
    case let n as Expression:
      return getCFG(n)
    default: 
      dump(stmt)
      fatalError("statement type not supported")

    // Other types we may wish to support in future

    // case let n as FunctionDeclaration:
    // case let n as ImportDeclaration: 
    // case let n as InitializerDeclaration: 
    // case let n as OperatorDeclaration: 
    // case let n as PrecedenceGroupDeclaration: 
    // case let n as ProtocolDeclaration: 
    // case let n as StructDeclaration: 
    // case let n as SubscriptDeclaration: 
    // case let n as TypealiasDeclaration:
    // case let n as CompilerControlStatement: 
    // case let n as DoStatement: 
    // case let n as DeinitializerDeclaration: 
    // case let n as LabeledStatement: 
    // case let n as EnumDeclaration: 
    // case let n as ThrowStatement:
    // case let n as ReturnStatement: 
    // case let n as ExtensionDeclaration: 
  }
}

func getNode(_ expr: Expression) -> Node {
  switch expr {
    case let assignment as AssignmentOperatorExpression:
      return Node(
        range: expr.sourceRange,
        type: .expression,
        defRange: assignment.leftExpression.sourceRange
      )
    case let binaryOp as BinaryOperatorExpression:
      switch binaryOp.binaryOperator {
        // Support the standard library assignment operators
        case "=":
          return Node(
            range: expr.sourceRange,
            type: .expression,
            defRange: binaryOp.leftExpression.sourceRange
          )
        case "*=", "/=", "%=", "+=", "-=", "<<=", ">>=", "&=", "|=", "^=": 
          return Node(
            range: expr.sourceRange,
            type: .expression,
            defRange: binaryOp.leftExpression.sourceRange,
            defRangeContainsRefs: true
          )
        default:
          return Node(
            range: expr.sourceRange,
            type: .expression
          )
      }
    default:
      return Node(
        range: expr.sourceRange,
        type: .expression
      )
  }
}

func getNode(_ pattern: AST.Pattern) -> Node {
  return Node(
    range: pattern.sourceRange,
    type: .pattern
  )
}

// If we are getting the PartialCFG of an Expression directly,
// then we just want a wrapper that has this expression as an entry point and moves on
func getCFG(_ expr: Expression) -> PartialCFG {
  let node = getNode(expr)
  return PartialCFG(
    nodes: [node],
    edges: [node: [.passiveNext]],
    entryPoint: .node(node)
  )
}

func getCFG(_ elseClause: IfStatement.ElseClause) -> PartialCFG {
  switch elseClause {
    case let .else(codeBlock):
      return getCFG(codeBlock)
    case let .elseif(ifStatement):
      return getCFG(ifStatement)
  }
}

func getCFG(_ pattern: AST.Pattern) -> PartialCFG {
  let node = getNode(pattern)
  return PartialCFG(
    nodes: [node],
    edges: [
      node: [.patternMatch, .patternNotMatch]
    ],
    entryPoint: .node(node)
  )
}

func getCFG(_ cond: Condition) -> PartialCFG {
  switch cond {
    case .expression(let e):
      let node = Node(
        range: e.sourceRange,
        type: .condition
      )
      return PartialCFG(
        nodes: [node],
        edges: [
          node: [.conditionFail, .conditionHold]
        ],
        entryPoint: .node(node)
      )
    case .availability(_):
      fatalError("availability conditions not supported")
    case .case(_ , _):
      fatalError("case conditions not supported")
    case .let(let pattern, let expression):
      // Hack - the start point of this range is the start of the pattern, the end point is the end of the expression
      // Really, this should include the let/var keyword
      let node = Node(
        range: SourceRange(start: pattern.sourceRange.start, end: expression.sourceRange.end),
        type: .condition,
        defRange: pattern.sourceRange
      )
      return PartialCFG(
        nodes: [node],
        edges: [
          node: [.conditionFail, .conditionHold]
        ],
        entryPoint: .node(node)
      )
    case .var(let pattern, let expression):
      // Hack - the start point of this range is the start of the pattern, the end point is the end of the expression
      // Really, this should include the let/var keyword
      let node = Node(
        range: SourceRange(start: pattern.sourceRange.start, end: expression.sourceRange.end),
        type: .condition,
        defRange: pattern.sourceRange
      )
      return PartialCFG(
        nodes: [node],
        edges: [
          node: [.conditionFail, .conditionHold]
        ],
        entryPoint: .node(node)
      )
  }
  return PartialCFG.empty
}
func getCFG(_ conds: [Condition]) -> PartialCFG {
  return PartialCFG(
    chainingCFGs: conds.map { getCFG($0) },
    withContext: { (currentCfg: PartialCFG, nextCfg: PartialCFG?) in
      [
        .conditionHold: nextCfg?.entryPoint ?? .conditionHold
      ]
    }
  )
}

func getPatternChainCFG(_ switchCase: SwitchStatement.Case, subjectUSR: USR) -> PartialCFG {
  switch switchCase {
  case .`case`(let items, _):
    for item in items {
      if item.whereExpression != nil {
        fatalError("where expression in switch patterns are not supported")
      }
    }

    let patternCFGs: [PartialCFG] = items.map {
      let cfg = getCFG($0.pattern)
      // Hack - tell the patterns that they reference the subject
      cfg.nodes.first?.artificialReferences.insert(subjectUSR)
      return cfg
    }

    return PartialCFG(
      chainingCFGs: patternCFGs,
      withContext: { currentPattern, nextPattern in 
        [
          // If there is another pattern then chain to that one,
          // otherwise it's a non-match
          .patternNotMatch: nextPattern?.entryPoint ?? .patternNotMatch
        ]
      }
    )
  case .`default`(_):
    // Everything matches the default case in a switch statement
    return PartialCFG(
      nodes: [],
      edges: [:],
      entryPoint: .patternMatch
    )
  }
}

func getBodyCFG(_ switchCase: SwitchStatement.Case) -> PartialCFG {
  let statements: [Statement]
  switch switchCase {
    case .`case`(_, let foundStatements): 
      statements = foundStatements
    case .`default`(let foundStatements):
      statements = foundStatements
  }

  return getCFG(statements).applying(context: [
    .breakStatement: .passiveNext
  ])
}
