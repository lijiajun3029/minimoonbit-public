enum Expression {
  Number(Int)
  Plus(Expression, Expression)
  Minus(Expression, Expression)
  Multiply(Expression, Expression)
  Divide(Expression, Expression)
} derive(Show)

type Parser[V] (ArrayView[@lex.Token]) -> (V, ArrayView[@lex.Token])?

pub fn parse[V](
  self : Parser[V],
  tokens : ArrayView[@lex.Token]
) -> (V, ArrayView[@lex.Token])? {
  (self._)(tokens)
}

fn ptoken(predicate : (@lex.Token) -> Bool) -> Parser[@lex.Token] {
  fn {
    [hd, .. as tl] => if predicate(hd) { Some((hd, tl)) } else { None }
    [] => None
  }
}

fn map[I, O](self : Parser[I], f : (I) -> O) -> Parser[O] {
  fn {
    input =>
      match self.parse(input) {
        Some((token, rest)) => Some((f(token), rest))
        None => None
      }
  }
}

fn and[V1, V2](self : Parser[V1], parser2 : Parser[V2]) -> Parser[(V1, V2)] {
  fn {
    input =>
      self
      .parse(input)
      .bind(
        fn {
          (value, rest) =>
            parser2
            .parse(rest)
            .map(fn { (value2, rest2) => ((value, value2), rest2) })
        },
      )
  }
}

fn or[Value](self : Parser[Value], parser2 : Parser[Value]) -> Parser[Value] {
  fn {
    input =>
      match self.parse(input) {
        None => parser2.parse(input)
        Some(_) as result => result
      }
  }
}

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

let number : Parser[Expression] = ptoken(
  fn {
    @lex.Token::Number(_) => true
    _ => false
  },
).map(fn { Number(value) => Expression::Number(value) })

// 定义互递归函数
// atomic = Value / "(" expression ")"
fn atomic(tokens : ArrayView[@lex.Token]) -> (Expression, ArrayView[@lex.Token])? {
  lparen
  .and(
    expression, // 引用函数
  )
  .and(rparen)
  .map(fn { ((_, expr), _) => expr })
  .or(number)
  .parse(tokens)
}

fn combine(tokens : ArrayView[@lex.Token]) -> (Expression, ArrayView[@lex.Token])? {
  Parser(atomic)
  .and(
    ptoken(
      fn {
        Mul | Div => true
        _ => false
      },
    )
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
            e, (Mul, expr) => Multiply(e, expr)
            e, (_, expr) => Divide(e, expr)
          },
        )
      }
    },
  )
  .parse(tokens)
}

fn expression(tokens : ArrayView[@lex.Token]) -> (Expression, ArrayView[@lex.Token])? {
  Parser(combine)
  .and(
    ptoken(
      fn {
        Add | Sub => true
        _ => false
      },
    )
    .and(combine)
    .many(),
  )
  .map(
    fn {
      (e, list) => {
        let result = list.fold(
          init=e,
          fn {
            e, (Add, expr) => Plus(e, expr)
            e, (_, expr) => Minus(e, expr)
          },
        )
        println("fold: \{e} \{list} -> \{result}")
        result
      }
    },
  )
  .parse(tokens)
}

pub let parser : Parser[Expression] = Parser(expression)

test {
  let input = "1 + 2 - 3"
  let tokens = []
  @lex.lex({ str: input, offset: 0, array: tokens })
  inspect!(tokens, content="[Number(1), Add, Number(2), Sub, Number(3)]")
  let (expr, _) = parser.parse(tokens[:]).unwrap()
  inspect!(expr, content="Minus(Plus(Number(1), Number(2)), Number(3))")
  let input = "1 + 2 * 3 - 6"
  let tokens = []
  @lex.lex({ str: input, offset: 0, array: tokens })
  inspect!(
    tokens,
    content="[Number(1), Add, Number(2), Mul, Number(3), Sub, Number(6)]",
  )
  let (expr, _) = parser.parse(tokens[:]).unwrap()
  inspect!(
    expr,
    content="Minus(Plus(Number(1), Multiply(Number(2), Number(3))), Number(6))",
  )
}
