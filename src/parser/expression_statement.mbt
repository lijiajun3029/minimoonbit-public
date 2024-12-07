// 定义互递归函数
// atomic = "(" expression ")" | Value
// 使用组合子构建的解析器atomic：从左到右解析表达式或数值tokens
fn atomic(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
  lparen
  .and(
    // statements, // 引用函数,statements函数自动类型转换为Parser
    expression  // 暂时仅支持
  )
  .and(rparen)
  .map(fn { ((_, expr), _) => expr })   // 忽略括号
  .or(if_statement)
  .or(number)
  .or(add_sub_number)
  .or(boolean)
  // .or(bool_expression)
  .or(var)
  .or(add_sub_var)
  // .or(statement())
  .parse(tokens)
}

// 使用组合子构建的解析器combine：从左到右解析atomic和乘或除运算符（递归）
fn combine(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
  Parser(atomic)
  .and(
    mul_div.map(map_op)
    .and(atomic)
    .many()
  )
  .map(
    fn {
      (e, list) => {
        println("combine fold: \{e} \{list}")
        list.fold(
          init=e,
          fn { 
            e,(Some(op),expr)=>
                match op{
                @types.Op::Mul => @types.Syntax::Prim(e, expr, @types.Op::Mul,kind=None)
                @types.Op::Div => @types.Syntax::Prim(e, expr, @types.Op::Div,kind=None)
                _ => @util.die("不应该出现在这里")
                }
            _,_ => @util.die("不应该出现在这里")
          },
        )
      }
    },
  )
  .parse(tokens)
}

// 使用组合子构建的解析器expression：从左到右解析combine和加或减运算符（递归）
fn expression(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
  Parser(combine)
  .and(
    add_sub.map(map_op)
    .and(combine)
    .many(),
  )
  // .and(separator)
  .map(
    fn {
      (e, list) => {
        let result = list.fold(
          init=e,
          fn {
              e,(Some(op),expr)=>
                  match op{
                    @types.Op::Add => @types.Syntax::Prim(e, expr,@types.Op::Add,kind=None)
                    @types.Op::Sub => @types.Syntax::Prim(e, expr,@types.Op::Sub,kind=None)
                    _ => @util.die("不应该出现在这里")
                  }
              _,_ => @util.die("不应该出现在这里")
          },
        )
        println("开始解析表达式 \{tokens}")
        println("expression fold: \{e} \{list} -> \{result}")
        result
      }
    },
  )
  .parse(tokens)
}

// 布尔表达式解析器，支持比较运算符和布尔逻辑运算
fn bool_expression(tokens : ArrayView[@lex.Token]) -> (@types.Syntax, ArrayView[@lex.Token])? {
    // 解析基本布尔原子表达式，比如 (expression) 或者是一个具体的布尔值
    let atomic_bool_expr = lparen
        // .and(expression)  // 支持嵌套的表达式
        .and(statement())   // todo check
        .and(rparen)
        .map(fn { ((_, expr), _) => expr })   // 忽略括号
        .or(expression)
        .or(call_fn_stmt)

    // 解析比较操作符 ==, !=, <, <=, >, >=
    let compare_expr = 
        atomic_bool_expr
        // statement()
        // Parser(call_fn_stmt).or(expression)
        // expression
        // expression
        .and(
            eqeq.or(lteq)   // todo 
            .and(atomic_bool_expr)
            // .and(statement())
            // .and(expression)
        )
        .map(fn { (left, (_,right)) => 
            @types.Syntax::Eq(left,right)
            // match maybe_op_right {
            //     Some((op, right)) => @types.Syntax::Eq(left, right, op, kind=None),
            //     None => left  // 如果没有比较运算符，直接返回 atomic_bool_expr
            // }
        });

    compare_expr.parse(tokens)
}
