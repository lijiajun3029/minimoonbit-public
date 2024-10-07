// minimoonbit编程语言的词法单元列表，参考MiniMoonBit.g4文件

// Token枚举用于表示源代码中识别出的词法单元。
// issues
// 1、暂时保留所有token，等待删除部分token
// 2、minimoonbit中token部分命名和moonbit关键词相同
pub enum Token {
  Number(Int) //  整数
  Identifier(String)  // 标识符

  // 声明类型or调用函数
  Unit  // Unit
  Bool  // Bool
  Int   // Int
  Double  // Double
  Tuple // Tuple
  Array // Array

  Main  // main
  Not // not

  // 循环
  Loop  // loop
  For // for
  While // while

  // 一般关键词
  Let       //  let
  If        //  if
  Else      //  else
  Fn        //  fn
  True    // ture
  False    // false

  // 运算符号
  Add //  +
  Sub //  -
  Mul //  *  
  Div //  /

  Assign  // =
  EqEq // ==
  Lt // <
  Le  // <=
  Ne  // !=
  Ge  // >=
  Gt  // >

  // 标点符号
  Comma //  ,
  Semicolon //  ;
  Colon     //  :
  PathSep // ::
  // ！
  Question// ？

  // 括号
  LParen    //  (
  RParen    //  )
  LBracket  //  [
  RBracket  //  ]
  LBrace    //  {
  RBrace    //  }

  // 其他
  Arrow // ->
  Comment // 注释
  Newline // \n on linux or mac, \r\n on windows
  // WS // [ \t\r\n]+ -> skip
  // 等等
  
} derive(Show)