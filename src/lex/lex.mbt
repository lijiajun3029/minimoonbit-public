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
      context.offset += 1
      if context.offset<str.length(){
        if str[context.offset]=='>'{
          context.offset += 1
          array.push(Arrow)
        }else{
          array.push(Sub)
        }
      }else{
        array.push(Sub)
      }
      lex(context)
    }
    '*' => {
      array.push(Mul)
      context.offset += 1
      lex(context)
    }
    '/' => {
      context.offset += 1
      if context.offset<str.length(){
        if str[context.offset]=='/'{
          // context.offset += 1
          // array.push(Comment)
          while context.offset< str.length() {
              if str[context.offset]=='\n'{
                context.offset += 1
                break
              }else if str[context.offset]=='\r'{
                if str[context.offset+1]=='\n'{
                  context.offset += 2
                  break
                }
              }else{
                context.offset += 1
                continue
              }
          }
        }else{
          array.push(Div)
        }
      }else{
        array.push(Div)
      }
      lex(context)
    }
    '=' => {
      // todo ==, =>
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
      
      while context.offset< str.length() {
          if str[context.offset]=='\n'{
            context.offset += 1
          }else if str[context.offset]=='\r'{
            if str[context.offset+1]=='\n'{
              context.offset += 2
            }
          }else{
            break
          }
      }
      lex(context)
    }
    '}' => {
      context.array.push(RBrace)
      context.offset += 1

      while context.offset< str.length() { 
          if str[context.offset]=='\n'{
            context.offset += 1
          }else if str[context.offset]=='\r'{
            if str[context.offset+1]=='\n'{
              context.offset += 2
            }
          }else{
            break
          }
      }

  
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
    '\n' => {
      context.array.push(Newline) // 识别为LF(Line Feed) 换行符（linux or mac os）
      context.offset += 1
      lex(context)
    }
    '\r' => {
          // 检查下一个字符是否为 '\n'，如果是，将其作为单一的 Newline 处理（windows）
          context.offset += 1
          if str[context.offset]=='\n'{
            context.array.push(Newline) // 识别为LF(Line Feed) 换行符
            context.offset += 1
            lex(context)
          }
    }
    ' ' | '\t'  => {
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
      while context.offset< str.length() { 
          if str[context.offset]=='\n'{
            context.offset += 1
          }else if str[context.offset]=='\r'{
            if str[context.offset+1]=='\n'{
              context.offset += 2
            }
          }else{
            break
          }
      }
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

  let array = []
  lex({ str: "let a=Int(11)\nlet b:Int =1", offset: 0, array })
  println(array)
  inspect!(
    array,
    content="[Let, Identifier(\"a\"), Assign, Int, LParen, Number(11), RParen, Newline, Let, Identifier(\"b\"), Colon, Int, Assign, Number(1)]"
  )

  // 多行表达式
  let input = "1/2-3 \n4*5+6"
  let tokens = []
  lex({ str: input, offset: 0, array: tokens })
  println(tokens)
  inspect!(
    tokens,
    content="[Number(1), Div, Number(2), Sub, Number(3), Newline, Number(4), Mul, Number(5), Add, Number(6)]",
  )
  // 多行let todo check type
  let array = []
  lex({ str: "let 1=Int(11)\nlet 2:Int =1", offset: 0, array })
  println(array)
  inspect!(
    array,
    content="[Let, Number(1), Assign, Int, LParen, Number(11), RParen, Newline, Let, Number(2), Colon, Int, Assign, Number(1)]"
  )

  println("TODO lex")
  println("------------")
  println("------------")
}