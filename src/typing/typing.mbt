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
  println("找到类型变量所代表的实际类型：\{t1}和\{t2}")
  if physical_equal(t1, t2) { return }
  match (t1, t2) {
    (Int, Int) | (Bool, Bool) | (Unit, Unit) | (Double, Double) => ()
    (Var({val:None} as tvar), ty) | (ty, Var({val:None} as tvar) ) => {
    // (Var({val:None} ) as tvar , ty) | (ty, Var({val:None}) as tvar ) => {
      // check_occur!(tvar, ty) // 自引用检查:  None(None and array(None))
      tvar.val = Some(ty)
    }
    (Var({val:Some(type1)}), type2) | (type1, Var({val:Some(type2)}) ) => {
      // (Var({val:None} ) as tvar , ty) | (ty, Var({val:None}) as tvar ) => {
     // check_occur!(tvar, ty) // 自引用检查:  None(None and array(None))
      unify!(type1,type2)
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

fn check_occur(tvar: @types.Type, ty: @types.Type) -> Unit!TyErr {
    println("检查自引用: tvar=\{tvar}, ty=\{ty}")
    match ty {
        // 如果目标类型是一个变量，递归检查它的内部类型
        Var({ val: Some(inner_ty) } ) as tvar2 => {
            if physical_equal(tvar, ty) {
                // 如果tvar和tvar2是同一个变量，检测到自引用，抛出错误
                raise TyErr("类型变量的自引用错误")
            } else {
                // 递归检查内部类型
                check_occur!(tvar, inner_ty)
            }
        }
        // 如果是函数类型，递归检查参数和返回值类型
        Fun(params, result_ty) => {
            for param_ty in params {
                check_occur!(tvar, param_ty)
            }
            check_occur!(tvar, result_ty)
        }
        // 如果是元组类型，递归检查每个元素
        Tuple(types) => {
            for elem_ty in types {
                check_occur!(tvar, elem_ty)
            }
        }
        // 如果是数组类型，递归检查元素类型
        Array(elem_ty) => {
            check_occur!(tvar, elem_ty)
        }
        // 对于其他基本类型，不需要继续检查
        _ => ()
    }
}


// 类型推导
fn infer(ctx: LocalCtx, e: @types.Syntax) -> @types.Type!TyErr {
    println("\n进入infer")
    println("局部上下文：\{ctx}")
    println("全局上下文：\{extenv}")
    println("语句：\{e}\n")

    match e {
        // 简单的类型推导
        Unit => Unit
        Bool(_) => Bool
        Int(_) => Int
        Double(_) => Double
        Neg(x, kind=_) => {
          infer!(ctx, x)
        }
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
                      println("未定义:\{x}")
                      let t = new_tvar();
                      extenv[x] = t;
                      t
                    }
            }
        }
        // 表达式
        Prim(syntax1,syntax2,_)=>{
            let type1=infer!(ctx,syntax1)
            let type2=infer!(ctx,syntax2)
            unify!(type1,type2)
            type1
        }
        // Let((String, Type), Syntax, Syntax) // let _: _ = _; _
        Let((var_name,var_type),prim,rest)=>{
            let prim_type=infer!(ctx, prim)
            unify!(var_type,prim_type)
            // let tmp_ctx = ctx.add(var_name,var_type)
            // println("\{tmp_ctx}")
            // println("\{ctx}")
            // ctx本身不可变，返回的tmp_ctx是可用的临时上下文
            println("let extenv:\{extenv}")
            extenv[var_name]=var_type
            println("let extenv:\{extenv}")
            infer!(ctx, rest)
        }
        // 定义函数，支持递归函数的类型推导
        LetRec({ name: (fun_name, fun_type), args: params, body: body }, rest) => {
            println("LetRec")
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
            // let params_ty1 = infer!(env_with_f,params_ty)
            unify!(fun_type, Fun(params_ty, syntax_type))
            // let body_ty = infer!(env_with_params, body)
            // unify!(fun_type, Fun(params_ty, body_ty))
            println(env_with_f)
            println(rest)
            // infer!(env_with_f, rest)
            println("函数定义检查完毕：\{fun_type}")
            extenv[fun_name]=fun_type
            // 函数定义默认返回一个Unit吧:)
            @types.Type::Unit
        }
        // 调用函数的类型推导
        App(fun_name, args) => {
            println("App局部上下文：\{ctx}")
            println("App全局上下文：\{extenv}")
            println("App的函数：\{fun_name}")

            // 推导出调用函数的类型
            let mut f_ty = infer!(ctx, fun_name)
            println("推导之后的函数定义类型：\{f_ty}")
            let mut tmp_ctx = LocalCtx::new()

            match f_ty{
              Var(f)=> {
                match (f.val, fun_name){
                  (None, @types.Syntax::Var(fun_name_string)) => {
                    // 匹配为None时，表明为匿名函数，此时调用该匿名函数，将原来的类型变量更新Fun而不非Var
                    let args_type= [new_tvar()]   // 暂且默认给一个参数
                    f_ty=Fun(args_type, new_tvar())
                    println(ctx)
                    tmp_ctx = ctx.remove(fun_name_string).add(fun_name_string,f_ty)
                    println(ctx)
                    println(tmp_ctx)
                  }
                  _ => {
                    tmp_ctx=ctx
                  }
                }
              }
              _ => tmp_ctx=ctx

            }
            println("更新之后的函数定义的类型：\{f_ty}\n")

            let args_ty = []
            for arg in args {
                println("\{fun_name}函数调用的参数类型：\{arg}")
                match arg{
                  Var(var_name)=>{
                    match fun_name{
                      Var(fun_name_string)=>{
                        if var_name==fun_name_string{
                          @util.die("\{arg}自引用")
                        }else{
                          println("\{arg}没有自引用")
                        }
                      }
                    }
                  }
                  _ => println("\{arg}没有自引用")
                }
                args_ty.push(infer!(tmp_ctx, arg))
            }
            println("更新之后的函数调用的参数类型：\{args_ty}")
            let return_type=new_tvar()
            unify!(f_ty, Fun(args_ty, return_type ))
            println("\{fun_name}函数调用返回类型：\{return_type}")
            println("函数调用结束\n")
            return_type
        }
        // 处理其他语法的匹配
        // _ => unimplemented!() // 这里可以添加更多的处理逻辑
    }
}

// 清理类型变量
fn deref_type(t: @types.Type) -> @types.Type {
    println("清理类型变量：\{t}")
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
// 全局的表:记录外部函数的类型
pub let extenv : Map[String, @types.Type]={"print_int":Fun([Int],Unit)}
// 局部的表:记录函数内部的变量和局部函数的类型，（嵌套作用域采用不可变数据结构，避免变量和局部函数的参数因命名相同而发生干涉。）
// type LocalCtx @immut/hashmap.T[String,@types.Type]
typealias LocalCtx = @immut/hashmap.T[String, @types.Type]   // 为某类型起别名
pub fn typing(ast : @types.Syntax) -> @types.Syntax!TyErr {
    let ctx = LocalCtx::new()
    // let ctx = LocalCtx::new().add("print_int",@types.Type::Unit)
    match ast{
      // 匹配过滤Seq
      @types.Syntax::Seq(ast_array)=>{
        println("等待类型检查：\{ast_array}")
        for one_ast in ast_array{
            println("\n开始类型检查：\{one_ast}")
            unify!(Unit, infer!(ctx, one_ast))    // 默认每个独立的语句结束之后，返回类型为Unit
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