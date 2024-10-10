// 词法解析的上下文
pub struct Context {
    is_top_level: Bool
    // current_scope: Vec<String>, // 用于维护当前作用域的栈
    // defined_variables: HashMap<String, String>, // 变量名与类型的映射
    // defined_functions: HashMap<String, (Vec<String>, String)>, // 函数名与参数及返回类型的映射
    // current_type: Option<String>, // 当前类型
    // errors: Vec<String>, // 收集的错误信息
    // current_module: Option<String>, // 当前模块名称
    // imported_modules: Vec<String>, // 导入的模块
    in_loop: Bool // 是否在循环内
    in_conditional: Bool // 是否在条件语句内
    is_async: Bool // 是否为异步上下文
    is_generator: Bool // 是否为生成器上下文
}