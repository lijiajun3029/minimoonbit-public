// minimoonbit词法解析

pub struct Context {
  str : String
  mut offset : Int
  array : Array[Token]
}

pub fn lex(context : Context) -> Unit {
  // 方法1
  // 基于字符匹配，进行状态转移
  let { offset, str, array } = context
  if offset >= str.length() {
    return
  }
  
  match str[offset] {
    // 运算符
    '+' => {
      array.push(Add)
      context.offset += 1
      lex(context)
    }
    '-' => {
      // todo ->
      array.push(Sub)
      context.offset += 1
      lex(context)
    }
    '*' => {
      array.push(Mul)
      context.offset += 1
      lex(context)
    }
    '/' => {
      // todo // (\r\n)
      array.push(Div)
      context.offset += 1
      lex(context)
    }
    '=' => {
      // todo ==
      array.push(Assign)
      context.offset += 1
      lex(context)
    }
    '>' => {
      // todo >=
      array.push(Gt)
      context.offset += 1
      lex(context)
    }
    '<' => {
      // todo <=
      array.push(Lt)
      context.offset += 1
      lex(context)
    }
    // 括号
    '(' => {
      array.push(LParen)
      context.offset += 1
      lex(context)
    }
    ')' => {
      array.push(RParen)
      context.offset += 1
      lex(context)
    }
    '{' => {
      context.array.push(LBrace)
      context.offset += 1
      lex(context)
    }
    '}' => {
      context.array.push(RBrace)
      context.offset += 1
      lex(context)
    }
    '[' => {
      context.array.push(LBracket)
      context.offset += 1
      lex(context)
    }
    ']' => {
      context.array.push(RBracket)
      context.offset += 1
      lex(context)
    }
    ' ' | '\n' | '\t' | '\r' => {
      // 空格等直接忽略
      context.offset += 1
      lex(context)
    }
    ',' => {
      context.array.push(Comma)
      context.offset += 1
      lex(context)
    }
    ';' => {
      context.array.push(Semicolon)
      context.offset += 1
      lex(context)
    }
    ':' => {
      // todo ：：
      context.array.push(Colon)
      context.offset += 1
      lex(context)
    }

    ch => if is_number(ch) {
            // 数字
            lex_number(context)
          } else if is_alpha(ch) { 
            // 关键字和标识符
            lex_identifier(context)
          } else {
            panic()
          }
  }
}

test {
  let array = []
  lex({ str: "-10123 -+ - 523 103 (5))", offset: 0, array })
  inspect!(
    array,
    content="[Sub, Number(10123), Sub, Add, Sub, Number(523), Number(103), LParen, Number(5), RParen, RParen]",
  )

  let array = []
  lex({ str: "let a=1", offset: 0, array })
  inspect!(
    array,
    content="[Let, Identifier(\"a\"), Assign, Number(1)]"
  )

  let array = []
  lex({ str: "let b1=11", offset: 0, array })
  println(array)
  inspect!(
    array,
    content="[Let, Identifier(\"b1\"), Assign, Number(11)]"
  )

  let array = []
  lex({ str: "let a=Int(11)", offset: 0, array })
  println(array)
  inspect!(
    array,
    content="[Let, Identifier(\"a\"), Assign, Int, LParen, Number(11), RParen]"
  )

  println("TODO lex")
}