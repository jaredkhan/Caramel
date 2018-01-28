import AST
import Source

func getCFG(_ decl: TopLevelDeclaration) -> CFG {
  let internalCFG = getCFG(decl.statements)
  let startNode = BasicBlock(
    range: SourceRange.EMPTY,
    type: .start
  )

  let partialCFG = CFG(
    nodes: [startNode],
    edges: [
      startNode: [internalCFG.entryPoint]
    ],
    entryPoint: .basicBlock(startNode)
  )

  return partialCFG.merging(with: internalCFG)
}

func getCFG(_ block: CodeBlock) -> CFG {
  return getCFG(block.statements)
}

func getCFG(_ statements: [Statement]) -> CFG {
  return CFG(
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

func getCFG(_ stmt: Statement) -> CFG {
  // Check if declaration
  // Check type of statement
  switch stmt {
    case let n as ConstantDeclaration: 
      let block = BasicBlock(range: n.sourceRange, type: .expression)
      return CFG(
        nodes: [block],
        edges: [block: [.passiveNext]],
        entryPoint: .basicBlock(block)
      )
    case let n as VariableDeclaration: 
      let block = BasicBlock(range: n.sourceRange, type: .expression)
      return CFG(
        nodes: [block],
        edges: [block: [.passiveNext]],
        entryPoint: .basicBlock(block)
      )
    case let n as BreakStatement: 
      let block = BasicBlock(range: n.sourceRange, type: .breakStatement)
      return CFG(
        nodes: [block],
        edges: [block: [.breakStatement]],
        entryPoint: .basicBlock(block)
      )
    case let n as ContinueStatement: 
      let block = BasicBlock(range: n.sourceRange, type: .continueStatement)
      return CFG(
        nodes: [block],
        edges: [block: [.continueStatement]],
        entryPoint: .basicBlock(block)
      )
    case let n as DeferStatement: 
      let block = BasicBlock(range: n.sourceRange, type: .breakStatement)
      return CFG(
        nodes: [block],
        edges: [block: [.breakStatement]],
        entryPoint: .basicBlock(block)
      )
    case let n as FallthroughStatement: 
      let block = BasicBlock(range: n.sourceRange, type: .fallthroughStatement)
      return CFG(
        nodes: [block],
        edges: [block: [.switchFallthrough]],
        entryPoint: .basicBlock(block)
      )
    case let n as ForInStatement: 
      // The control flow for a for in loop goes as follows:
      // - Evalute collection,
      // - Match a value from collection with the pattern,
      // - If can assign to the pattern, enter the block, otherwise continue
      // - Resolve any `break` or `continue` appropriately
      // - When reach the end of the block, go back to the pattern
      let collectionCFG = getCFG(n.collection)
      let patternCFG = getCFG(n.item.matchingPattern)
      let bodyCFG = getCFG(n.codeBlock)
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
      // TODO: What exit mechanisms can a guard use?
      let elseCFG = getCFG(n.codeBlock)
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
      let bodyCFG = getCFG(n.codeBlock)
      let elseCFG = n.elseClause.map(getCFG) ?? CFG.empty
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

      let conditionExpressionNode = getNode(n.conditionExpression)

      let bodyCFG = getCFG(n.codeBlock).applying(context: [
        .passiveNext: .basicBlock(conditionExpressionNode),
        .continueStatement: .basicBlock(conditionExpressionNode),
        .breakStatement: .passiveNext
      ])

      return CFG(
        nodes: [conditionExpressionNode],
        edges: [
          conditionExpressionNode: [
            // condition either leads to body or passivenext
            bodyCFG.entryPoint,
            .passiveNext
          ]
        ],
        entryPoint: bodyCFG.entryPoint
      ).merging(with: bodyCFG)
    case let n as SwitchStatement: 
      let subject = getNode(n.expression)
      var caseCFGs: [CFG] = []
      
      for caseStatement in n.cases.reversed() {
        caseCFGs.append(getCFG(caseStatement).applying(context: [
          // For each case, if it's not the last then point it to the next one
          // Remove the nextCase edge from the final case cfg
          // because if we enter the final case, by Swift semantics, it cannot fail
          // Not every case can fail so shold never propagate a nextCase to a passiveNext
          .nextCase: caseCFGs.last?.entryPoint
        ]))
      }

      let partialCFG = CFG(
        nodes: [subject],
        edges: [
          subject: [
            caseCFGs.first?.entryPoint ?? .passiveNext
          ]
        ],
        entryPoint: .basicBlock(subject)
      )

      return partialCFG.merging(with: caseCFGs)
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

func getNode(_ expr: Expression) -> BasicBlock {
  return BasicBlock(
    range: expr.sourceRange,
    type: .expression
  )
}

// If we are getting the CFG of an Expression directly,
// then we just want a wrapper that has this expression as an entry point and moves on
func getCFG(_ expr: Expression) -> CFG {
  let node = getNode(expr)
  return CFG(
    nodes: [node],
    edges: [node: [.passiveNext]],
    entryPoint: .basicBlock(node)
  )
}

func getCFG(_ elseClause: IfStatement.ElseClause) -> CFG {
  switch elseClause {
    case let .else(codeBlock):
      return getCFG(codeBlock)
    case let .elseif(ifStatement):
      return getCFG(ifStatement)
  }
}

/// 
func getCFG(_ pattern: Pattern) -> CFG {
  return CFG.empty
}
func getCFG(_ cond: Condition) -> CFG {
  switch cond {
    case .expression(let e):
      let node = BasicBlock(
        range: e.sourceRange,
        type: .ifCondition
      )
      return CFG(
        nodes: [node],
        edges: [
          node: [.conditionFail, .conditionHold]
        ],
        entryPoint: .basicBlock(node)
      )
    case .availability(_):
      fatalError("availability conditions not supported")
    case .case(_ , _):
      fatalError("case conditions not supported")
    case .let(_, _), .var(_, _):
      fatalError("optional binding not supported")
  }
  return CFG.empty
}
func getCFG(_ conds: [Condition]) -> CFG {
  return CFG(
    chainingCFGs: conds.map { getCFG($0) },
    withContext: { (currentCfg: CFG, nextCfg: CFG?) in
      [
        .conditionHold: nextCfg?.entryPoint ?? .conditionHold
      ]
    }
  )
}
func getCFG(_ switchCase: SwitchStatement.Case) -> CFG {
  return CFG.empty
}
