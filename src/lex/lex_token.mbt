// Token枚举用于表示源代码中识别出的词法单元。
pub enum Token {
  Number(Int) //  整数
  Identifier(String)  // 标识符

  Bool    // Bool
  Int     // Int
  Double  // Double
  True    // ture
  False    // false
  // 关键词
  Let       //  let
  If        //  if
  Else      //  else
  Fn        //  fn
  // 符号
  Add //  +
  Sub //  -
  Mul //  *  
  Div //  /
  Comma //  ,
  Semicolon //  ;
  Colon     //  :
  LParen    //  (
  RParen    //  )
  LBracket  //  [
  RBracket  //  ]
  LBrace    //  {
  RBrace    //  }
} derive(Show)