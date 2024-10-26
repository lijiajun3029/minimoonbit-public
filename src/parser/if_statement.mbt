// if语句解析器
fn if_statement(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    ptoken(fn {
        @lex.Token::If => true
        _ => false
    })
    // .and(expression) // 解析表达式条件
    .and(bool_expression) // 解析复杂条件语句
    // .and(statement()) // 解析条件语句
    // .and(statements) // 解析复杂条件语句
    .and(block)      // 解析 then 分支
    .and(ptoken(fn {
        @lex.Token::Else => true
        _ => false
    }))
    .and(block)      // 解析 else 分支
    .map(fn {
        ((((_, condition), then_branch), _,),else_branch) => @types.Syntax::If(condition, then_branch, else_branch)
    })
    .parse(tokens)
}