// 表达式词法解析

pub struct Context {
  str : String
  mut offset : Int
  array : Array[Token]
}

pub fn push_token() -> Unit{
  // 推入一个词法单元并递增偏移量
}

pub fn lex(context : Context) -> Unit {
  let { offset, str, array } = context
  if offset >= str.length() {
    return
  }
  // 大量分支容易遗漏
  match str[offset] {
    '+' => {
      array.push(Add)
      context.offset += 1
      lex(context)
    }
    '-' => {
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
      array.push(Div)
      context.offset += 1
      lex(context)
    }
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
    }
    '[' => {
      context.array.push(LBracket)
      context.offset += 1
    }
    ']' => {
      context.array.push(RBracket)
      context.offset += 1
    }
    ' ' | '\n' | '\t' | '\r' => {
      context.offset += 1
      lex(context)
    }
    ';' => {
      context.array.push(Semicolon)
      context.offset += 1
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

// 匹配数字
// 整数，todo浮点数
fn is_number(ch: Char) -> Bool {
  ch >= '0' && ch <= '9'
}

fn lex_number(context : Context) -> Unit {
  let { offset, str, .. } = context
  let number = "\{str[offset]}"
  context.offset += 1
  lex_number_rest(context, number)
}

fn lex_number_rest(context : Context, number : String) -> Unit {
  let { offset, str, array } = context
  if offset >= str.length() {
    array.push(Number(@strconv.parse_int?(number).unwrap()))
    return
  }
  let ch = str[offset]
  if ch >= '0' && ch <= '9' {
    context.offset += 1
    lex_number_rest(context, number + ch.to_string())
  } else {
    array.push(Number(@strconv.parse_int?(number).unwrap()))
    lex(context)
  }
}

// 匹配关键词和标识符
// 判断字符是否为字母或下划线
fn is_alpha(ch: Char) -> Bool {
  (ch >= 'a' && ch <= 'z') ||
  (ch >= 'A' && ch <= 'Z') ||
  ch == '_'
}

// 判断字符是否为字母或数字或下划线
fn is_alphanumeric(ch: Char) -> Bool {
  is_alpha(ch) || (ch >= '0' && ch <= '9')
}

// 匹配关键词和标识符
fn lex_identifier(context: Context) -> Unit {
  let start = context.offset
  while context.offset < context.str.length() && is_alphanumeric(context.str[context.offset]) {
    context.offset += 1
  }
  let ident = context.str.substring(start=start,end=context.offset)
  match ident {
    "let" => context.array.push(Let)
    "if" => context.array.push(If)
    "else" => context.array.push(Else)
    "fn" => context.array.push(Fn)
    "true" => context.array.push(True)
    "false" => context.array.push(False)
    _ => context.array.push(Identifier(ident))
  }
}

test {
  let array = []
  lex({ str: "-10123 -+ - 523 103 (5))", offset: 0, array })
  inspect!(
    array,
    content="[Sub, Number(10123), Sub, Add, Sub, Number(523), Number(103), LParen, Number(5), RParen, RParen]",
  )
  // todo
  // let array = []
  // lex({ str: "let a=1", offset: 0, array })
  // inspect!(
  //   array,
  //   content="[Let, a, ",
  // )
  println("TODO lex")
}