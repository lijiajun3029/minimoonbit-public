// 判断一个单词是否符合语法，单词本身以及位置等。
fn ptoken(predicate : (@lex.Token) -> Bool) -> Parser[@lex.Token] {
  // 直接返回一个函数作为Parser[@lex.Token]
  fn {  // 省略参数
    [hd, .. as tl] => if predicate(hd) { Some((hd, tl)) } else { None }
    [] => None
  }
}

fn ptoken_skip(predicate : (@lex.Token) -> Bool) -> Parser[@lex.Token] {
  // 直接返回一个函数作为Parser[@lex.Token];跳过失败，并不消耗token
  fn {  // 省略参数
    [hd, .. as tl] as all=> {
      if predicate(hd) {
        Some((hd, tl)) 
      } else {
        // println("ptoken_skip \{all}")
        // None
        Some((hd,all))
        // Some((@lex.Token::Arrow,tl))
      }
    }
    [] => None
  }
}
// ptoken_skip2

fn ptoken_not(predicate : (@lex.Token) -> Bool) -> Parser[@lex.Token] {
  // 直接返回一个函数作为Parser[@lex.Token];跳过失败，并不消耗token
  fn {  // 省略参数
    [hd, .. as tl] as all=> {
      if predicate(hd) {
        println("test test00")
        None
      } else {
        // println("ptoken_skip \{all}")
        // None
        println("test test11")
        Some((hd,all))
        // Some((@lex.Token::Arrow,tl))
      }
    }
    [] => {
      println("test test")
      None
    }
  }
}
