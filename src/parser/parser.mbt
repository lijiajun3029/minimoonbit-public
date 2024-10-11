// 语法解析

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
  // match tokens{
  //   []=> None
  // }
  (self._)(tokens)  //  self._: self.0
}

// 判断一个单词是否符合语法，单词本身以及位置等。
fn ptoken(predicate : (@lex.Token) -> Bool) -> Parser[@lex.Token] {
  // 直接返回一个函数作为Parser[@lex.Token]
  fn {  // 省略参数
    [hd, .. as tl] => if predicate(hd) { Some((hd, tl)) } else { None }
    [] => None
  }
}

// 对解析结果进行变换
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
      .bind(  // 调用bind者，本身为None时，直接返回None；否则则表示parser1解析成功,解析结果为value,继续使用parser2解析剩余的rest
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
    println("Many 1")
    println("input: \{input}")
    println("self.parse(input): \{self.parse(input)}")
    let cumul = []
    let mut rest = input
    
    // 方法1
    while true{
      match self.parse(rest){
        None => break 
        Some((v, rest_)) => {
          cumul.push(v)
          rest=rest_
        }
      }
    }
    println("many()成功解析: \{cumul}")
    println("many()尚未解析: \{rest}")
    Some((cumul, rest))

    // 方法2
    // loop self.parse(rest) {
    //   None => break Some((cumul, rest))
    //   Some((v, rest_)) => {
    //     println("Many 2")
    //     println("value: \{v}")
    //     println("rest_: \{rest_}")
    //     println("self.parse(rest_): \{self.parse(rest_)}")
    //     cumul.push(v)
    //     rest = rest_
    //     continue self.parse(rest) // to drop
    //   }
    // }

  }
}

fn zero_one[Value : Show](self : Parser[Value]) -> Parser[Array[Value]] {
  fn(input) {
    println("Many 1")
    println("input: \{input}")
    println("self.parse(input): \{self.parse(input)}")
    let cumul = []
    let mut rest = input
    
    // 方法1
    while true{
      match self.parse(rest){
        None => break 
        Some((v, rest_)) => {
          cumul.push(v)
          rest=rest_
        }
      }
    }
    println("many()成功解析: \{cumul}")
    println("many()尚未解析: \{rest}")
    Some((cumul, rest))

    // 方法2
    // loop self.parse(rest) {
    //   None => break Some((cumul, rest))
    //   Some((v, rest_)) => {
    //     println("Many 2")
    //     println("value: \{v}")
    //     println("rest_: \{rest_}")
    //     println("self.parse(rest_): \{self.parse(rest_)}")
    //     cumul.push(v)
    //     rest = rest_
    //     continue self.parse(rest) // to drop
    //   }
    // }

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

let separator : Parser[@lex.Token] = ptoken(
    fn {
      Semicolon | Newline => true
      _ => false
    },
)
let colon  : Parser[@lex.Token] = ptoken(fn {
    Colon => true
    _ => false
})

let comma  : Parser[@lex.Token] = ptoken(fn {
    Comma => true
    _ => false
})

let assign : Parser[@lex.Token] = ptoken(fn {
    Assign => true
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
      @types.Syntax::Neg(@types.Syntax::Var(name),kind=Some(@types.Kind::Int))
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
    })
  
// 定义互递归函数
// atomic = "(" expression ")" | Value
// 使用组合子构建的解析器atomic：从左到右解析表达式或数值tokens
fn atomic(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
  lparen
  .and(
    // statements, // 引用函数,statements函数自动类型转换为Parser
    expression  // 暂时仅支持
  )
  .and(rparen)
  .map(fn { ((_, expr), _) => expr })   // 忽略括号
  .or(number)
  .or(add_sub_number)
  .or(boolean)
  .or(var)
  .or(add_sub_var)
  .parse(tokens)
}

// 使用组合子构建的解析器combine：从左到右解析atomic和乘或除运算符（递归）
fn combine(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
  Parser(atomic)
  .and(
    mul_div.map(map_op)
    .and(atomic)
    .many()
  )
  .map(
    fn {
      (e, list) => {
        println("combine fold: \{e} \{list}")
        list.fold(
          init=e,
          fn { 
            e,(Some(op),expr)=>
                match op{
                @types.Op::Mul => @types.Syntax::Prim(e, expr, @types.Op::Mul,kind=None)
                @types.Op::Div => @types.Syntax::Prim(e, expr, @types.Op::Div,kind=None)
                _ => @util.die("不应该出现在这里")
                }
            _,_ => @util.die("不应该出现在这里")
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
    add_sub.map(map_op)
    .and(combine)
    .many(),
  )
  // .and(separator)
  .map(
    fn {
      (e, list) => {
        let result = list.fold(
          init=e,
          fn {
              e,(Some(op),expr)=>
                  match op{
                    @types.Op::Add => @types.Syntax::Prim(e, expr,@types.Op::Add,kind=None)
                    @types.Op::Sub => @types.Syntax::Prim(e, expr,@types.Op::Sub,kind=None)
                    _ => @util.die("不应该出现在这里")
                  }
              _,_ => @util.die("不应该出现在这里")
          },
        )
        println("开始解析表达式 \{tokens}")
        println("expression fold: \{e} \{list} -> \{result}")
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
  .and(colon.and(parse_type).zero_one())  // todo
  .and(assign)
  .and(expression)  // 暂时仅支持expression
  // .and(statements)
  // .and(separator)
  // .and(statements) // 去掉连续语句
  .map(fn {
    // (((((((_,name),_,), ty), _), expr1), _), expr2) => @types.Syntax::Let((name, ty), expr1, expr2) 
    // ((((((_,name),_,), ty), _), expr1), _) => @types.Syntax::Let((name, ty), expr1, @types.Syntax::Unit) 
    // (((((_,name),_,), ty), _), expr1) => @types.Syntax::Let((name, ty), expr1, @types.Syntax::Unit) 
    (((((_,name)), array_ty), _), expr1) => {
      let mut ty=@types.Type::Int
      if array_ty.length()>0{
        ty=array_ty[0].1
      }
      @types.Syntax::Let((name, ty), expr1, @types.Syntax::Unit) 
    }
  })
  .parse(tokens)
}

// if语句解析器
fn if_statement(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    ptoken(fn {
        @lex.Token::If => true
        _ => false
    })
    .and(expression) // 解析条件表达式
    // .and(statements) // 解析多语句
    .and(block)      // 解析 then 分支
    .and(ptoken(fn {
        @lex.Token::Else => true
        _ => false
    }))
    .and(block)      // 解析 else 分支
    .map(fn {
        ((((_, condition), then_branch), _,),else_branch) => @types.Syntax::If(condition, then_branch, else_branch)
    })
    .parse(tokens)
}

fn fn_statement(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    ptoken(
      fn {
        Fn => true
        _ => false
      }
    )
    .and(
      ptoken(
        fn {
        Identifier(_) => true
        _ => false
      })
      .or(
        ptoken(
        fn {
          Main => true
          _ => false
        })
      )
      .map(fn {
        Identifier(fun_name) => fun_name  // 中间解析,可以简化最终解析
        _  => "main"
      })
    )
    .and(
        lparen
        .and(
            // 解析参数列表，可以是空或一个或多个参数
            ptoken(fn { 
                Identifier(_) => true
                _ => false 
            }).map(fn {
                Identifier(arg_name) => arg_name
            })
            .and(ptoken(fn { Colon => true;_ => false }))
            .and(parse_type)
            .map(fn { ((arg_name, _), arg_type) => (arg_name,arg_type) })   // 参数类型,中间解析,可以简化最终解析
            .and(
                comma
                // .or(ptoken(fn { 
                //     RParen => true
                //     _ => false 
                // }))
            )
            // .map(fn { (param, _) => param })
            .many()
        )
        .and(rparen)
    )
    .and(block)// 解析函数体
    .map(fn {
        (((_,fun_name), ((_,array_params),_)), body)=> {
          let params=[]
          for param in array_params{
            params.push(param.0)
          }
          let fundef :@types.Fundef={name:(fun_name,@types.Type::Unit), args:params, body:body}
          @types.Syntax::LetRec(fundef, @types.Syntax::Unit)
        }
        // (_,body)=>{
        //   let params=[]
        //   let fundef :@types.Fundef={name:("main",@types.Type::Unit), args:params, body:body}
        //   @types.Syntax::LetRec(fundef, @types.Syntax::Unit)
        // }
    })
    // .and(ptoken(fn { RParen => true ;_ => false }))
    .parse(tokens)
}

// 
fn call_fn_stmt(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    ptoken(
        fn {
        Fun_name(_) => true
        _ => false
      }).map(fn {
        Fun_name(fun_name) => fun_name  // 中间解析,可以简化最终解析
      })
    .and(lparen)
    .and(ptoken(fn { 
          Identifier(_) => true
                _ => false 
          }).map(fn {
              Identifier(arg_name) => arg_name
          })
          .and(
            comma.or(
              ptoken(fn { 
                Identifier(_) => true
                      _ => false 
                })).map(fn {
                    Identifier(arg_name) => arg_name
                })
            .many()
          )
          // .and(comma).many()
        )
    .and(rparen)
    .map(fn {  _ => {
      println("test")
      @types.Syntax::Unit
    }})
    .parse(tokens)
}

// ()
fn lparen_rparen_stmt(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    lparen
    .and(rparen)
    .map(fn {  _ => {
      @types.Syntax::Unit
    }})
    .parse(tokens)
}

fn block(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    lbrace
    // lbrace.many().map(fn {_ => None})
    // .and(expression)
    // .and(statement()) // 解析单个语句
    .and(statements) // 解析多个语句
    .and(separator.many())
    .and(rbrace)
    .map(fn { (((_, stmts), _,),rbrace) => {
      println("消耗了： \{rbrace}")
      println("block内语法是 \{stmts}")
      stmts
    }})
    .parse(tokens)
}


// fn brace_stmt(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
//     rbrace
//     .map(fn { rbrace_=> {
//       println("消耗了： \{rbrace_}")
//       // rbrace_
//     } })
//     .parse(tokens)
// }

fn statement() -> Parser[@types.Syntax] {
  fn (tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
      println("statement tokens: \{tokens}")
      let mut ast= None
      if tokens.length()>0{
        println(tokens.length())
        let parsers = [
            fn_statement,
            let_statement,
            if_statement,
            expression,  // 表达式也是一种语句
            lparen_rparen_stmt,
            call_fn_stmt,
            // lbrace,  // 单独解析}
        ]
        // todo spilt tokens
        //   RBrace
        let mut n =1
        for parser in parsers{
          println("第\{n}个解析器开始解析")
          ast= parser(tokens)
          println("ast: \{ast}")
          n = n+1
          match ast{
            None => println("none")
            _ => break
          }

          // if ast{  //  error
          //   break
          // }
          
        }
      }
      ast
  }
}
// fn statements(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
//     // 使用 many 来解析零个或多个语句，并将它们组合成一个块
//     statement().many().map(fn { stmts =>
//        // 将多个语句组合成一个序列，可以选择如何表示
//        // 这里假设我们有一个 `Seq` 变体来表示语句序列
//        // @types.Syntax::Seq(stmts)
//         stmts[0]
//     }).parse(tokens)  
// }

// fn statements(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
//     statement().and(
//       separator.and(statements)
//       // statements
//       ).map(fn { (stmt, (sep, rest)) =>
//             match rest {
//               @types.Syntax::Unit => {
//                   @types.Syntax::Seq([stmt])
//               }
//               _ => {
//                   @types.Syntax::Seq([stmt, rest])
//               }
//           }
//         })
//         .parse(tokens)  
// }    

fn statements(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
  // println("22")
    statement().and(
      separator.and(statement()).many() // 0次或多次
      // statements
      ).map(
        // fn { [(stmts,_)]=>
        //           @types.Syntax::Seq([stmts])
        // }
        fn {
      (first_stmt, list) => {
        let stmts=[]
        stmts.push(first_stmt)
        println("33")
        let result = list.fold(
          init=first_stmt,
          fn {
              first_stmt,(_,one_statement)=>{
                stmts.push(one_statement)
                first_stmt
              }
              _,_=> @util.die("不应该出现在这里")
          },
        )
        println("stmts fold: \{first_stmt} \{list} -> \{result}")
        println("stmts: \{stmts}")
        @types.Syntax::Seq(stmts)
        // stmts
      }
        }
        )
        .parse(tokens)  
}

// fn statements(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
//     statement()
//         .and(
//             (separator().and(statements)).or(Parser::pure(Syntax::Unit))
//         )
//         .map(fn { (stmt, rest) =>
//             match rest {
//                 Syntax::Unit => {
//                     if stmt == Syntax::Unit {
//                         Syntax::Seq([])
//                     } else {
//                         Syntax::Seq([stmt])
//                     }
//                 },
//                 _ => Syntax::Seq([stmt, rest])
//             }
//         })
//         .parse(tokens)
// }


// 扩展 parser 以支持 let 语句和表达式
// pub fn parse_syntax(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
//   // 优先级等 todo
//   match let_statement(tokens){
//     None=>match expression(tokens){
//       None => None
//       _ as ast => ast
//     }
//     _ as ast => ast
//   }
// }

pub fn parse_syntax(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
  statements(tokens)
}



test {
  let input = "1 + 2 * 3 - 6;"
  let tokens = []
  @lex.lex({ str: input, offset: 0, array: tokens })
  inspect!(
    tokens,
    content="[Number(1), Add, Number(2), Mul, Number(3), Sub, Number(6), Semicolon]",
  )
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  // inspect!(expr,content="Prim(Prim(Int(1), Prim(Int(2), Int(3), Mul, kind=None), Add, kind=None), Int(6), Sub, kind=None)",)
  inspect!(expr,content="Seq([Prim(Prim(Int(1), Prim(Int(2), Int(3), Mul, kind=None), Add, kind=None), Int(6), Sub, kind=None)])",)

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
    content="Seq([Prim(Prim(Int(1), Int(2), Div, kind=None), Int(3), Sub, kind=None)])",
  )

  // 多行表达式
  // 字符串输入
  let input = "1 + 2 - 3;2;"
  // 词法解析
  let tokens = []
  @lex.lex({ str: input, offset: 0, array: tokens })
  inspect!(tokens, content="[Number(1), Add, Number(2), Sub, Number(3), Semicolon, Number(2), Semicolon]")
  // 语法解析（自顶向下的解释器组合子）
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  println(expr)
  // inspect!(expr, content="Prim(Prim(Int(1), Int(2), Add, kind=None), Int(3), Sub, kind=None)")
  inspect!(expr, content="Seq([Prim(Prim(Int(1), Int(2), Add, kind=None), Int(3), Sub, kind=None), Int(2)])")

  let input = "1/2-3 \n4*5+6"
  let tokens = []
  @lex.lex({ str: input, offset: 0, array: tokens })
  println(tokens)
  inspect!(
    tokens,
    content="[Number(1), Div, Number(2), Sub, Number(3), Newline, Number(4), Mul, Number(5), Add, Number(6)]",
  )
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  println(expr)
  inspect!(
    expr,
    content="Seq([Prim(Prim(Int(1), Int(2), Div, kind=None), Int(3), Sub, kind=None), Prim(Prim(Int(4), Int(5), Mul, kind=None), Int(6), Add, kind=None)])",
  )

  // let input = "+ + 2 * 3 - 6"  // 暂时报错, moonbit支持不报错
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
  inspect!(expr, content="Seq([Let((\"a\", Int), Int(1), Unit), Int(2)])")

  // 多行let
  let tokens = []
  @lex.lex({ str: "let a:Int=1;let b:Int=1", offset: 0, array: tokens })
  println(tokens)
  inspect!(
    tokens,
    content="[Let, Identifier(\"a\"), Colon, Int, Assign, Number(1), Semicolon, Let, Identifier(\"b\"), Colon, Int, Assign, Number(1)]"
  )
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  println(expr)
  inspect!(expr, content="Seq([Let((\"a\", Int), Int(1), Unit), Let((\"b\", Int), Int(1), Unit)])")

  let tokens = []
  @lex.lex({ str: "let a:Int=1\nlet b:Int=1", offset: 0, array: tokens })
  println(tokens)
  inspect!(
    tokens,
    content="[Let, Identifier(\"a\"), Colon, Int, Assign, Number(1), Newline, Let, Identifier(\"b\"), Colon, Int, Assign, Number(1)]"
  )
  let (expr, _) = parse_syntax(tokens[:]).unwrap()
  println(expr)
  inspect!(expr, content="Seq([Let((\"a\", Int), Int(1), Unit), Let((\"b\", Int), Int(1), Unit)])")

  // if in file
  // moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/if_else.mbt  // success
  // moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/if_else2.mbt // failure  换行
  // moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/if.mbt // failure  缺少else
  // moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/if2.mbt  // failure  缺少else

  // fn in file
}
