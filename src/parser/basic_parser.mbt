// 使用type定义一个新类型：这个新类型是一个函数(输入token数组，输出解析V和剩余token数组)
type Parser[V] (ArrayView[@lex.Token]) -> (V, ArrayView[@lex.Token])?

// 基础解析器：解析词法单元（并将词法单元映射为语法单元）
let lparen : Parser[@lex.Token] = ptoken(
  fn {
    LParen => true
    _ => false
  },
)

let rparen : Parser[@lex.Token] = ptoken(
  fn {
    RParen => true
    _ => false
  },
)

let lparen_skip : Parser[@lex.Token] = ptoken_skip(
  fn {
    LParen => true
    _ => false
  },
)

let rparen_skip : Parser[@lex.Token] = ptoken_skip(
  fn {
    RParen => true
    _ => false
  },
)

let lparen_not : Parser[@lex.Token] = ptoken_not(
  fn {
    LParen => true
    _ => false
  },
)

let rparen_not : Parser[@lex.Token] = ptoken_not(
  fn {
    RParen => true
    _ => false
  },
)

let lbrace : Parser[@lex.Token] = ptoken(
  fn {
    LBrace => true
    _ => false
  },
)

let rbrace : Parser[@lex.Token] = ptoken(
  fn {
    RBrace => true
    _ => false
  },
)

let rbrace_skip : Parser[@lex.Token] = ptoken_skip(
  fn {
    RBrace => true
    _ => false
  },
)

let rbrace_detect : Parser[@lex.Token] = ptoken_detect(
  fn {
    RBrace => {
      println("检测到了'}'")
      true
    }
    _ => false
  },
)

let mul_div : Parser[@lex.Token] = ptoken(
    fn {
      Mul | Div => true
      _ => false
    },
)

let add_sub : Parser[@lex.Token] = ptoken(
    fn {
      Add | Sub => true
      _ => false
    },
)

let semicolon : Parser[@lex.Token] = ptoken(
    fn {
      Semicolon => true
      _ as neg_semicolon=> {
        println("\{neg_semicolon}并非Semicolon")
        false
        }
    },
)

let semicolon_detect : Parser[@lex.Token] = ptoken_detect(
  fn {
    Semicolon => {
      println("检测到了';'")
      true
    }
    _ => false
  },
)

let newline : Parser[@lex.Token] = ptoken(
    fn {
      Newline => true
      _ => false
    },
)


let newline_skip : Parser[@lex.Token] = ptoken_skip(
    fn {
      Newline => true
      _ => false
    },
)

let separator : Parser[@lex.Token] = ptoken(
    fn {
      Semicolon | Newline => true
      _ => false
    },
)

let separator_skip : Parser[@lex.Token] = ptoken_skip(
    fn {
      Semicolon | Newline => true
      _ => false
    },
)

let colon  : Parser[@lex.Token] = ptoken(fn {
    Colon => true
    _ => false
})

let colon_skip  : Parser[@lex.Token] = ptoken_skip(fn {
    Colon => true
    _ => false
})

let comma  : Parser[@lex.Token] = ptoken(fn {
    Comma => true
    _ => false
})

let comma_skip  : Parser[@lex.Token] = ptoken_skip(fn {
    Comma => true
    _ => false
})

let assign : Parser[@lex.Token] = ptoken(fn {
    Assign => true
    _ => false
})

let eqeq : Parser[@lex.Token] = ptoken(fn {
    EqEq => true
    _ => false
})

let lteq : Parser[@lex.Token] = ptoken(fn {
    LtEq => true
    _ => false
})

let arrow : Parser[@lex.Token] = ptoken(fn {
    Arrow => true
    _ => false
})

let arrow_skip : Parser[@lex.Token] = ptoken_skip(fn {
    Arrow => true
    _ => false
})

// let pure : Parser[@lex.Token] = ptoken(
//     fn {
//       _ => true
//     },
// )

let number : Parser[@types.Syntax] = ptoken(
  fn {
    @lex.Token::Number(_) => true
    @lex.Token::Number_Double(_) => true
    _ => false
  },
).map(fn {
  Number(value) => @types.Syntax::Int(value)
  Number_Double(value) => @types.Syntax::Double(value)
  _ => @util.die("")
  })

let add_sub_number : Parser[@types.Syntax] = add_sub.and(ptoken(
  fn {
    @lex.Token::Number(_) => true
    @lex.Token::Number_Double(_) => true
    _ => false
  },
)).map(fn {
  (Add,Number(value)) => {
    @types.Syntax::Neg(@types.Syntax::Int(value),kind=Some(@types.Kind::Int))
  }
  (Sub,Number(value)) => {
    @types.Syntax::Neg(@types.Syntax::Int(value),kind=Some(@types.Kind::Int))
  }
  (Add,Number_Double(value)) => {
    @types.Syntax::Neg(@types.Syntax::Double(value),kind=Some(@types.Kind::Double))
  }
  (Sub,Number_Double(value)) => {
    @types.Syntax::Neg(@types.Syntax::Double(value),kind=Some(@types.Kind::Double))
  }
  _ => @util.die("")
  })

let boolean : Parser[@types.Syntax] = ptoken(
    fn {
        @lex.Token::True | @lex.Token::False => true
        _ => false
    },
).map(fn {
    @lex.Token::True => @types.Syntax::Bool(true)
    @lex.Token::False => @types.Syntax::Bool(false)
    _ => @util.die("Unexpected token in boolean parser")
})

let var : Parser[@types.Syntax] =ptoken(fn { // 变量
    Identifier(_) => true
    _ => false
  }).map(fn {
    @lex.Token::Identifier(name) => @types.Syntax::Var(name)
    })

let add_sub_var : Parser[@types.Syntax] = add_sub.and(ptoken(fn { // 变量
    Identifier(_) => true
    _ => false
  })).map(fn {
    (Add,Identifier(name)) => {
      // @types.Syntax::Neg(@types.Syntax::Var(name),kind=Some(@types.Kind::Int))
      @types.Syntax::Var(name)
    }
    (Sub,Identifier(name)) => {
      @types.Syntax::Neg(@types.Syntax::Var(name),kind=Some(@types.Kind::Int))
    }
    _ => @util.die("add_sub_var错误")
})

let parse_type : Parser[@types.Type] = ptoken(
  fn {
      Unit => true
      Bool => true
      Int => true
      Double => true
      Tuple => true
      Array => true
      _ => false
    },
  ).map(fn {
    Unit => @types.Type::Unit
    Bool => @types.Type::Bool
    Int => @types.Type::Int
    Double => @types.Type::Double
    // Tuple => @types.Type::Tuple(Array[Type])  // todo
    // todo
    _ => @types.Type::Var({val:None})
    })

let parse_type_skip : Parser[@types.Type] = ptoken_skip(
  fn {
      Unit => true
      Bool => true
      Int => true
      Double => true
      Tuple => true
      Array => true
      _ => false
    },
  ).map(fn {
    Unit => @types.Type::Unit
    Bool => @types.Type::Bool
    Int => @types.Type::Int
    Double => @types.Type::Double
    // Tuple => @types.Type::Tuple(Array[Type])  // todo
    // todo
    _ => @types.Type::Var({val:None})
    })
    
// 参数是函数类型解析器，用于解析 (A) -> B 的形式
let fun_type_parser: Parser[@types.Type] = 
  lparen_skip  // 匹配左括号表示开始函数类型
  .and(
    parse_type_skip
  )
  .and(
    rparen_skip  // 匹配右括号表示结束参数类型
  )
  .and(
    arrow_skip  // 匹配箭头表示返回类型
    .and(parse_type_skip)  // 递归解析返回类型
    .map(fn { (_, return_type) => return_type })
  )
  .map(fn { (((_, param_types), _), return_type) => {
      // for param_type in param_types{
      //   @types.Type::Fun(param_type, return_type)  // 构建函数类型
      // }
      // println(param_types)
      println("测试fun")
      @types.Type::Fun([param_types], return_type)  // 构建函数类型
    }
  });

let fun_fun_type_parser: Parser[@types.Type] = 
  lparen_skip  // 匹配左括号表示开始函数类型
  .and(
    fun_type_parser
  )
  .and(
    rparen_skip  // 匹配右括号表示结束参数类型
  )
  .and(
    arrow_skip  // 匹配箭头表示返回类型
    .and(fun_type_parser) // 递归解析返回类型
    .map(fn { (_, return_type) => return_type })
  )
  .map(fn { (((_, param_types), _), return_type) => {
      // for param_type in param_types{
      //   @types.Type::Fun(param_type, return_type)  // 构建函数类型
      // }
      println(param_types)
      @types.Type::Fun([@types.Type::Int], return_type)  // 构建函数类型
    }
  });