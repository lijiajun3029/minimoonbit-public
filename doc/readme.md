## MiniMoonBit.g4 
  g4（grammar 4）语法文件，ANTLR(another tool for language recognition)语法文件，用于描述编程语言的结构和规则。其有以下部分：

    // Top-level
    // Function declarations
    // Statements
    // x[y] = z
    // Expressions, in order of precedence
    // Value expressions
    // Types
    // Tokens

  例如：

  Statements部分中'let' IDENTIFIER type_annotation? '=' expr ';' stmt表示一个赋值语句的结构和规则，具体解释如下：

    'let':  表示关键词let，用于声明一个变量。
    IDENTIFIER: 表示变量名，通常是一个标识符。
    type_annotation?: 表示类型注解是可选的，可能指定变量的类型。
    '=':  表示赋值操作符，指将右侧的表达式结果赋值给左侧的变量。
    expr: 表示一个表达式，可以是任何有效的表达式。
    ';':  表示语句的结束符号。
    stmt: 表示该赋值语句后跟随的其他语句。

  Tokens部分中NUMBER: [0-9]+表示一个单词NUMBER的结构和规则，即0-9数字匹配1次或多次（有限次，超出数据类型最大长度即为错误输入）。

  ## src/top.mbt
    Syntax: 各种语法结构；例如Double(3.14)，相关用例请见src/utils.mbt测试部分。
    Kind:   基本数据类型。
    Op:     基本运算符，这与Syntax中Prim相关联，后者用来表示具体的基本运算操作。  
    Fundef: 函数定义。
    Type:   各种数据类型。
    Type::is_ptr_like   判断类型是否为ptr的函数。
    Type::is_float_like 判断类型是否像float的函数。
    Type::size_of   计算类型大小的函数。
    Type::op_equal  判断两个类型是否相同的函数。

