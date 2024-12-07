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
    parser_context.nested_nubmer+=1
    println("block: \{parser_context}")
    lbrace
    // lbrace.many().map(fn {_ => None})
    // .and(expression)
    // .and(statement()) // 解析单个语句
    .and(statements) // 解析多个语句
    .and(separator.many())
    .and(rbrace)
    // .and(rbrace_skip)
    .map(fn { (((_, stmts), _,),rbrace) => {
      println("消耗了： \{rbrace}")
      println("block内语法是 \{stmts}")
      parser_context.nested_nubmer-=1
      if parser_context.nested_nubmer==0{
        parser_context.is_top_level=true
      }
      println(parser_context)
      stmts
    }})
    .parse(tokens)
}

fn block_end(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    rbrace_detect.and(semicolon_detect).map(fn{
      r=>{
        println("bolck_end: \{r}")
        @types.Syntax::Unit
    }})
    .parse(tokens)
}

fn statement() -> Parser[@types.Syntax] {
  fn (tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
      println("statement tokens: \{tokens}")
      let mut ast= None
      if tokens.length()>0{
        println(tokens.length())
        let parsers = {
            "block_end": block_end,
            "lparen_rparen_stmt": lparen_rparen_stmt,
            "expression": expression,  // 表达式也是一种语句，note：表达式中可以嵌套if语句，因此在if语句之前
            "fn_main_statement": fn_main_statement,
            "fn_statement": fn_statement,
            "fn_fn_statement": fn_fn_statement,  // 复杂函数定义
            "let_statement": let_statement,
            "if_statement": if_statement,
            "call_fn_stmt": call_fn_stmt,
            "bool_expression": bool_expression,
            // "newline_stmt": newline_stmt,

            "last_one": lparen_rparen_stmt, // 最后一个
        }
        for parser_name, parser in parsers{
          println("解析器\{parser_name}开始解析")
          if tokens[0]==@lex.Token::RBrace{
            // 检测是否右括号，避免陷入嵌套循环
            break
          }
          ast= parser(tokens)
          println("ast: \{ast}")
          match ast{
            None => {
              if parser_name=="last_one" && parser_context.is_top_level{
                // 目前在block内部完全可能遇到所有解析器都无法解析，因为内部和外部模式匹配不同。
                // 现在单独添加了‘}’解析，此处可优化掉
                @util.die("无法解析: \{tokens}")
              }
            }
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