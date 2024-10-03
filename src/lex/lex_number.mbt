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