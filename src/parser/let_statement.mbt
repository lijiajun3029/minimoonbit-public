// 添加 let 语句的解析器
fn let_statement(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
  ptoken(fn {
    @lex.Token::Let => true
    _ => false
  })
  .and(ptoken(fn {
    Identifier(_) => true
    _ => {
      @util.die("标识符错误")
    }
  }).map(fn {
    @lex.Token::Identifier(name) => name
    })
  )
  .and(colon.and(parse_type).zero_one())  // todo
  .and(assign)
  .and(expression)  // 暂时仅支持expression
  // .and(statements)
  // .and(separator)
  // .and(statements) // 去掉连续语句
  .map(fn {
    // (((((((_,name),_,), ty), _), expr1), _), expr2) => @types.Syntax::Let((name, ty), expr1, expr2) 
    // ((((((_,name),_,), ty), _), expr1), _) => @types.Syntax::Let((name, ty), expr1, @types.Syntax::Unit) 
    // (((((_,name),_,), ty), _), expr1) => @types.Syntax::Let((name, ty), expr1, @types.Syntax::Unit) 
    (((((_,name)), array_ty), _), expr1) => {
      let mut ty=@types.Type::Int
      if array_ty.length()>0{
        ty=array_ty[0].1
      }
      @types.Syntax::Let((name, ty), expr1, @types.Syntax::Unit) 
    }
  })
  .parse(tokens)
}