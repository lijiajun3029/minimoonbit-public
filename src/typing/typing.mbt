/// 类型检查：类型标注、类型推导、类型检查。
/// moonbit是一门静态类型编程语言。
/// 类型检查方法主要分为两大类：语法解析时检查、语法解析后检查
fn new_tvar() -> @types.Type {
    //  Var(t=None)
    Var({val:None})
 }
 
type! TyErr String
// 类型变量的归一化
fn unify(t1: @types.Type, t2: @types.Type) -> Unit!TyErr {
  println("开始归一化：\{t1}和\{t2}")
  let t1 = t1.repr()
  let t2 = t2.repr()
  if physical_equal(t1, t2) { return }
  match (t1, t2) {
    (Int, Int) | (Bool, Bool) | (Unit, Unit) | (Double, Double) => ()
    (Var({val:None} as tvar) , ty) | (ty, Var({val:None} as tvar) ) => {
      // check_occur!(tvar.val, ty) // 自引用检查:  None(None and array(None))
      tvar.val = Some(ty)
    }
    (Fun(args1,ret_ty1),Fun(args2,ret_ty2))=>{
      unify!(Tuple(args1),Tuple(args2))
      unify!(ret_ty1,ret_ty2)
    }
    (Tuple(array_type1),Tuple(array_type2))=>{
      if array_type1.length() != array_type2.length() {
        raise TyErr("Tuple长度不匹配")
      }
      for i=0; i<array_type1.length(); i=i+1 {
          unify!(array_type1[i], array_type2[i]) // 递归调用unify函数归一化每个元素
      }
    }
    (Array(type1),Array(type2))=>{
        unify!(type1, type2)
    }
    // .. // handle the function, tuple, and array @types.Type  
    _ => raise TyErr("类型变量的归一化错误")
  }
}
fn check_occur(t1: @types.Type?, t2: @types.Type) -> Unit!TyErr{
  raise TyErr("类型变量的自引用错误")
}

// 类型推导
fn infer(ctx: LocalCtx, e: @types.Syntax) -> @types.Type!TyErr {
    match e {
        // 简单的类型推导
        Unit => Unit
        Bool(_) => Bool
        Int(_) => Int
        Double(_) => Double
        Var(x) => 
            match ctx[x] {
                Some(t) => {
                  println("局部变量\{x}类型: \{t}")
                  t
                }
                None => 
                  match extenv[x]{
                    Some(t) => {
                      println("全局变量\{x}类型: \{t}")
                      t   
                    }
                    None =>{
                      let t = new_tvar();
                      extenv[x] = t;
                      t
                    }
            }
        }
        // 表达式
        // Let((String, Type), Syntax, Syntax) // let _: _ = _; _
        Let((var_name,var_type),prim,rest)=>{

            @types.Type::Unit
        }
        // 递归函数的类型推导
        LetRec({ name: (fun_name, fun_type), args: params, body: body }, rest) => {
            println(rest)
            let env_with_f = ctx.add(fun_name, fun_type)
            let params_ty = params.map(fn{(_, t)=> t})
            let mut env_with_params = env_with_f
            for p in params {
                env_with_params = env_with_params.add(p.0, p.1)
            }
            println(env_with_params)
            let mut syntax_type = @types.Type::Unit
            match body{
              // 使用Seq的缺点。
              Seq(syntax_array)=>{
                for syntax in syntax_array{
                  println("infer前: \{syntax}")
                  syntax_type = infer!(env_with_params, syntax)
                  println("infer后: \{syntax_type}")
                }
              }
            }
            // unify!(fun_type, Fun(params_ty, syntax_type))
            // let body_ty = infer!(env_with_params, body)
            // unify!(fun_type, Fun(params_ty, body_ty))
            println(env_with_f)
            println(rest)
            infer!(env_with_f, rest)
        }
        // 函数调用的类型推导
        App(fun_name, args) => {
            println(ctx)
            println(fun_name)
            let ret_ty = new_tvar()
            let f_ty = infer!(ctx, fun_name)
            println(f_ty)
            let args_ty = []
            for arg in args {
                println("函数调用的参数：\{arg}")
                args_ty.push(infer!(ctx, arg))
            }
            println(args_ty)
            println(ret_ty)
            unify!(f_ty, Fun(args_ty, ret_ty))
            ret_ty
        }
        // 处理其他语法的匹配
        // _ => unimplemented!() // 这里可以添加更多的处理逻辑
    }
}

// 清理类型变量
fn deref_type(t: @types.Type) -> @types.Type {
    match t {
        Fun(params, result) => Fun(params.map(fn { t => deref_type(t) }), deref_type(result))
        Tuple(types) => Tuple(types.map(fn { t => deref_type(t) }))
        Array(t) => Array(deref_type(t))
        Var({val:Some(t)} as tvar) => {
            let t = deref_type(t)
            tvar.val = Some(t)
            t
        }
        Var({val:None} as tvar) => {
            tvar.val = Some(Unit)
            Unit
        }
        t => t
    }
}

fn deref_term(syntax: @types.Syntax) -> @types.Syntax{ 
    // 实现细节
    @types.Syntax::Unit
}

// 类型推导的上下文
// 全局的表记录外部函数的类型
pub let extenv : Map[String, @types.Type]={"print_int":Fun([Int],Int)}
// 局部的表记录函数内部的变量和局部函数的类型，（嵌套作用域采用不可变数据结构，避免变量和局部函数的参数因命名相同而发生干涉。）
// type LocalCtx @immut/hashmap.T[String,@types.Type]
typealias LocalCtx = @immut/hashmap.T[String, @types.Type]   // 为某类型起别名
pub fn typing(ast : @types.Syntax) -> @types.Syntax!TyErr {
    let ctx = LocalCtx::new()
    // let ctx = LocalCtx::new().add("print_int",@types.Type::Unit)
    match ast{
      @types.Syntax::Seq(ast_array)=>{
        println(ast_array)
        for one_ast in ast_array{
            println(one_ast)
            unify!(Unit, infer!(ctx, one_ast))
            for ext_f, ext_t in extenv {
              extenv[ext_f] = deref_type(ext_t)
            }
            let tmp = deref_term(one_ast)
        }
        @types.Syntax::Unit
      }
      _ => {
        @util.die("并非Seq")
      }
    }
}