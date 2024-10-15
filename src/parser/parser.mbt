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

pub fn parse[V](
  self : Parser[V],
  tokens : ArrayView[@lex.Token]
) -> (V, ArrayView[@lex.Token])? {
  // match tokens{
  //   []=> None
  // }
  (self._)(tokens)  //  self._: self.0
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
  // and返回值为一个函数（输入input，成功则输出为((value1, value2), rest2)）
  // 调用bind者，本身为None时，直接返回None；否则则表示parser1解析成功,解析结果为value1和rest1,继续使用parser2解析rest1,解析结果为value2,rest2
  // 最后解析结果为((value1, value2), rest2)
  fn {
    input =>
      self
      .parse(input)
      .bind(
        fn {
          (value1, rest1) =>
            parser2
            .parse(rest1)
            .map(fn { 
              (value2, rest2) =>{ 
                ((value1, value2), rest2)
              }
             })
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

// ()
fn lparen_rparen_stmt(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    lparen
    .and(rparen)
    .map(fn {  _ => {
      @types.Syntax::Unit
    }})
    .parse(tokens)
}

// fn newline_stmt(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
//     newline_skip
//     // .many()
//     .map(fn {  _ => {
//       @types.Syntax::Unit
//     }})
//     .parse(tokens)
// }

fn block(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    parser_context.is_top_level=false
    println("block: \{parser_context}")
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
      parser_context.is_top_level=true
      println(parser_context)
      stmts
    }})
    .parse(tokens)
}

fn statement() -> Parser[@types.Syntax] {
  fn (tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
      println("statement tokens: \{tokens}")
      let mut ast= None
      if tokens.length()>0{
        println(tokens.length())
        let parsers = [
            fn_main_statement,
            fn_statement,
            let_statement,
            if_statement,
            expression,  // 表达式也是一种语句
            lparen_rparen_stmt,
            call_fn_stmt,
            // newline_stmt,
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
        }
      }
      ast
  }
}

fn statements(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    statement().and(
      separator_skip.and(statement()).many()
      // separator.and(statement()).many() // 0次或多次
      // statements
      ).map(
        fn {
      (first_stmt, list) => {
        let stmts=[]
        stmts.push(first_stmt)
        let result = list.fold(
          init=first_stmt,
          fn {
              first_stmt,(_,one_statement)=>{
                stmts.push(one_statement)
                first_stmt
              }
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

pub fn parse_syntax(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
  parser_context.token_length=tokens.length()
  statements(tokens)
}