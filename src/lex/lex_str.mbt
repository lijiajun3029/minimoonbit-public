// 部分编译器结合使用有限状态自动机和映射表。例如，使用DFA处理结构化的词法规则（如标识符、数字），同时使用映射表快速处理单字符Token（如运算符、括号等）。
fn lex_map(context : Context) -> Unit {
  // 方法2
  // 基于语法切割字符串（空格切割，数字和运算符切割等），然后进行单词映射。
  let { offset, str, array } = context
  if offset >= str.length() {
    return
  }
  // let token_key = str[offset]
  let token_key = "12"
  let token_value=token_map.get(token_key)
  match token_value{
    None=> panic()
    Some(token_value)=>match token_key.length(){
      1 => array.push(token_value)
      _ => if is_number(token_key[0]) { // 尚未实现判断字符串是否为数字
            // 数字
            lex_number(context)
          } else if is_alpha(token_key[0]) {  // 非关键词就是标识符
            // 关键字和标识符
            lex_identifier(context)
          } else {
            panic()
          }
    }
  }
  
}
