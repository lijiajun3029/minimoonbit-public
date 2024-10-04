// 语法解析

// Expression枚举用于构建表达式抽象语法树：每个枚举变体代表一种表达式且允许递归构建表达式。

// 解析操作符并映射到 Op 枚举
fn map_op(token: @lex.Token) -> Option[@types.Op] {
  match token {
    @lex.Token::Add => Some(@types.Op::Add)
    @lex.Token::Sub => Some(@types.Op::Sub)
    @lex.Token::Mul => Some(@types.Op::Mul)
    @lex.Token::Div => Some(@types.Op::Div)
    _ => None
  }
}

// 使用type定义一个新类型：这个新类型是一个函数。
type Parser[V] (ArrayView[@lex.Token]) -> (V, ArrayView[@lex.Token])?

pub fn parse[V](
  self : Parser[V],
  tokens : ArrayView[@lex.Token]
) -> (V, ArrayView[@lex.Token])? {
  (self._)(tokens)
}

// 判断一个单词是否符合语法，单词本身以及位置等。
fn ptoken(predicate : (@lex.Token) -> Bool) -> Parser[@lex.Token] {
  // 直接返回一个函数作为Parser[@lex.Token]
  fn {  // 省略参数
    [hd, .. as tl] => if predicate(hd) { Some((hd, tl)) } else { None }
    [] => None
  }
}

// 如果语法解析成功，对解析结果进行转化。
fn map[I, O](self : Parser[I], f : (I) -> O) -> Parser[O] {
  fn {
    input =>
      match self.parse(input) {
        Some((token, rest)) => Some((f(token), rest))
        None => None
      }
  }
}

// 顺序解析：顺序解析，若遇到失败则返回None，提前退出解析。
fn and[V1, V2](self : Parser[V1], parser2 : Parser[V2]) -> Parser[(V1, V2)] {
  fn {
    input =>
      self
      .parse(input)
      .bind(  // 调用bind者，本身为None，直接返回None；否则解析parser2
        fn {
          (value, rest) =>
            parser2
            .parse(rest)
            .map(fn { (value2, rest2) => ((value, value2), rest2) })
        },
      )
  }
}

// 尝试解析：尝试解析每一个部分，若都失败才返回None。
fn or[Value](self : Parser[Value], parser2 : Parser[Value]) -> Parser[Value] {
  fn {
    input =>
      match self.parse(input) {
        None => parser2.parse(input)
        Some(_) as result => result
      }
  }
}

// 重复解析：0次或多次，直到失败为止。
fn many[Value : Show](self : Parser[Value]) -> Parser[Array[Value]] {
  fn(input) {
    let cumul = []
    let mut rest = input
    println("Many")
    println(input)
    println(self.parse(input))
    loop self.parse(input) {
      None => Some((cumul, rest))
      Some((v, rest_)) => {
        println("Many")
        println(rest_)
        println(self.parse(rest_))
        cumul.push(v)
        rest = rest_
        continue self.parse(rest_)
      }
    }
  }
}

// 递归定义：延迟定义并未使用
fn Parser::ref[Value](ref : Ref[Parser[Value]]) -> Parser[Value] {
  fn(input) { ref.val.parse(input) }
}

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

let number : Parser[@types.Syntax] = ptoken(
  fn {
    @lex.Token::Number(_) => true
    _ => false
  },
).map(fn {
  Number(value) => @types.Syntax::Int(value)
  _ => @util.die("")
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
    })
  
// 定义互递归函数
// atomic = "(" expression ")" | Value
// 使用组合子构建的解析器atomic：从左到右解析表达式或数值tokens
fn atomic(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
  lparen
  .and(
    expression, // 引用函数,expression函数自动类型转换为Parser
  )
  .and(rparen)
  .map(fn { ((_, expr), _) => expr })
  .or(number)
  .parse(tokens)
}

// 使用组合子构建的解析器combine：从左到右解析atomic和乘或除运算符（递归）
fn combine(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
  Parser(atomic)
  .and(
    mul_div
    .and(atomic)
    .many(),
  )
  .map(
    fn {
      (e, list) => {
        println("fold: \{e} \{list}")
        list.fold(
          init=e,
          fn {
            e, (@lex.Token::Mul, expr) => @types.Syntax::Prim(e, expr,@types.Op::Mul,kind=None)
            e, (@lex.Token::Div, expr) => @types.Syntax::Prim(e, expr,@types.Op::Div,kind=None)
          },
        )
      }
    },
  )
  .parse(tokens)
}

// 使用组合子构建的解析器expression：从左到右解析combine和加或减运算符（递归）
fn expression(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
  Parser(combine)
  .and(
    add_sub
    .and(combine)
    .many(),
  )
  .map(
    fn {
      (e, list) => {
        let result = list.fold(
          init=e,
          fn {
            e, (Add, expr) => @types.Syntax::Prim(e, expr,@types.Op::Add,kind=None)
            e, (Sub, expr) => @types.Syntax::Prim(e, expr,@types.Op::Sub,kind=None)
          },
        )
        println("fold: \{e} \{list} -> \{result}")
        result
      }
    },
  )
  .parse(tokens)
}

// 添加 let 语句的解析器
fn let_statement(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
  ptoken(fn {
    @lex.Token::Let => true
    _ => false
  })
  .and(ptoken(fn {
    Identifier(_) => true
    _ => false
  }).map(fn {
    @lex.Token::Identifier(name) => name
    })
  )
  .and(ptoken(fn {
    Colon => true
    _ => false
  }))
  .and(parse_type) // 假设有一个解析类型的函数
  .and(ptoken(fn {
    Assign => true
    _ => false
  }))
  .and(expression)
  .and(ptoken(fn {
    Semicolon => true
    _ => false
  }))
  .and(expression)
  .map(fn {
    (((((((_,name),_,), ty), _), expr1), _), expr2) => @types.Syntax::Let((name, ty), expr1, expr2) 
  })
  .parse(tokens)
}

// 扩展 parser 以支持 let 语句和表达式
pub fn parse_syntax(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
  // 优先级等 todo
  match let_statement(tokens){
    None=>match expression(tokens){
      None => None
      _ as ast => ast
    }
    _ as ast => ast
  }
}

test {
  // 字符串输入
  let input = "1 + 2 - 3"
  // 词法解析
  let tokens = []
  @lex.lex({ str: input, offset: 0, array: tokens })
  inspect!(tokens, content="[Number(1), Add, Number(2), Sub, Number(3)]")
  // 语法解析（自顶向下的解释器组合子）
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  println(expr)
  inspect!(expr, content="Prim(Prim(Int(1), Int(2), Add, kind=None), Int(3), Sub, kind=None)")

  let input = "1 + 2 * 3 - 6"
  let tokens = []
  @lex.lex({ str: input, offset: 0, array: tokens })
  inspect!(
    tokens,
    content="[Number(1), Add, Number(2), Mul, Number(3), Sub, Number(6)]",
  )
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  inspect!(
    expr,    
    content="Prim(Prim(Int(1), Prim(Int(2), Int(3), Mul, kind=None), Add, kind=None), Int(6), Sub, kind=None)",
  )

  let input = "1/2-(3)"
  let tokens = []
  @lex.lex({ str: input, offset: 0, array: tokens })
  inspect!(
    tokens,
    content="[Number(1), Div, Number(2), Sub, LParen, Number(3), RParen]",
  )
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  inspect!(
    expr,
    content="Prim(Prim(Int(1), Int(2), Div, kind=None), Int(3), Sub, kind=None)",
  )

  // let input = "+ + 2 * 3 - 6"  // 报错
  // let tokens = []
  // @lex.lex({ str: input, offset: 0, array: tokens })
  // inspect!(
  //   tokens,
  //   content="[Add, Add, Number(2), Mul, Number(3), Sub, Number(6)]",
  // )
  // let (expr, _) = parser.parse(tokens[:]).unwrap()
  // inspect!(
  //   expr,
  //   content="Minus(Plus(Add, Multiply(Number(2), Number(3))), Number(6))",
  // )
  
  // let语句
  let tokens = []
  @lex.lex({ str: "let a:Int=1;2", offset: 0, array: tokens })
  println(tokens)
  inspect!(
    tokens,
    content="[Let, Identifier(\"a\"), Colon, Int, Assign, Number(1), Semicolon, Number(2)]"
  )
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  println(expr)
  inspect!(
    expr,
    content="Let((\"a\", Int), Int(1), Int(2))"
  )
}
