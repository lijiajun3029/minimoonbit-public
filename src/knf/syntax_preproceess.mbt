/// Preprocesses the syntax tree, extracting the contents of functions `main` and `init` to top-level.
pub fn KnfEnv::syntax_preprocess(
  self : KnfEnv,
  ast : @types.Syntax
) -> @types.Syntax {
  println("提示：开始提取mian和init函数到顶层")
  let init_array=[]
  let main_array=[]
  let other_ast_array=[]
  let all_ast_array=[]

  match ast{
    Seq(ast_array) => {
      for one_ast in ast_array{
          match one_ast{
            LetRec({name:(fun_name,fun_type), args:params, body:body}, Unit)=>{
              if fun_name == "init"{
                init_array.push(body)
                all_ast_array.push(body)
              }else if fun_name == "main"{  // init函数在包初始化的时候执行，main函数在init函数之后执行，其他顶层语句什么时候执行呢？(一测便知)
                main_array.push(body)
                all_ast_array.push(body)
              }else{
                other_ast_array.push(one_ast)
                all_ast_array.push(one_ast)
              }
            }
            _ => {
                other_ast_array.push(one_ast)
                all_ast_array.push(one_ast)
            }
          }

      }
    }
    _ => @util.die("竟然没有Seq😀")
  }
  // println("将init和main函数内容提取到顶层：\{@types.Syntax::Seq(init_array + main_array + other_ast_array)}")
  // Seq(init_array + main_array + other_ast_array)
  println("将init和main函数内容提取到顶层：\{@types.Syntax::Seq(all_ast_array)}")
  Seq(all_ast_array)
}
