// 定义本地环境为不可变hashmap
pub typealias LocalEnv = @immut/hashmap.T[String, Type]

// 定义KnfEnv结构体：可变计数器，外部不可变hashmap
struct KnfEnv {
  mut counter : Int
  externals : @immut/hashmap.T[String, Type]
}

// 定义KnfEnv结构体初始化方法
pub fn KnfEnv::new(externals : @immut/hashmap.T[String, Type]) -> KnfEnv {
  { counter: 1, externals }
}

// 从已经存在的Knf表达式中获得最大槽位来初始化KnfEnv的计数器
pub fn KnfEnv::init_counter_from_existing(
  self : KnfEnv,
  existing : Knf
) -> Unit {
  self.counter = knf_max_counter(existing) + 1
}

// 新建临时变量名，并更新计数器
fn KnfEnv::new_temp(self : KnfEnv) -> Name {
  let temp = Name::slot_only(self.counter)
  self.counter += 1
  temp
}

// 新建指定名称临时变量名，并更新计数器
fn KnfEnv::new_named_temp(self : KnfEnv, name : Name) -> Name {
  let counter = self.counter
  self.counter += 1
  { ..name, slot: counter }
}

// 转换函数：根据不同的节点类型进行处理
pub fn KnfEnv::to_knf(self : KnfEnv, ast : @types.Syntax) -> Knf! { // !Failure
  println("to_knf: \{ast}")
  match ast {
    // Trivial cases
    Unit => Unit
    Int(i) => Int(i)
    Double(i) => Double(i)
    Var(name) => {
      Knf::Var(Name::name_only(name))
    }
    
    Prim(a, b, op, ..) => { // 如何获得kind
      let a_name = self.new_temp()
      let b_name = self.new_temp()

      // let a_name = <a> in
      // let b_name = <b> in
      // a_name +-*/ b_name
      Knf::Let((a_name, @types.Type::Int), self.to_knf!(a),
          Knf::Let((b_name,@types.Type::Int), self.to_knf!(b), 
            match op{
              Add=>Knf::Add(a_name, b_name)
              Sub=>Knf::Sub(a_name, b_name)
              Mul=>Knf::Mul(a_name, b_name)
              Div=>Knf::Div(a_name, b_name)
            }
            )
      )
    }
    Let((name_str,name_type), expr, Unit) =>{
      Knf::Let(
        (Name::name_only(name_str),name_type), 
        self.to_knf!(expr),
        self.to_knf!(Unit)
      )
    }
    LetRec({name:(fun_name,fun_type), args:params, body:body}, Unit) =>{
        let new_params=[]
        for index, arg_arg_type in params{
          new_params.push((Name::name_only(arg_arg_type.0),arg_arg_type.1))
          println(index)
        }
        println("body: \{body}")
        Knf::LetRec(
          {name:Name::name_only(fun_name), ty:fun_type, args:new_params, body:self.to_knf!(body)}, 
          self.to_knf!(Unit)
        )
    }
    App(fun_name,array_params) => {
      println("\n提示App")
      let array_params_Name=[]
      for param in array_params{
        // 参数先to_knf,递归调用
        // 参数绑定变量名
        let tmp = self.new_temp()
        println("提示param: \{param}")
        let tmp_knf =Let((tmp,@types.Type::Int),
              self.to_knf!(param),
              Unit)
        knf_array.push(tmp_knf)
        array_params_Name.push(tmp)
        // array_params_Name.push(Name::name_only(self.to_knf!(param).to_string()))
      }
      match fun_name{
        Var(fun_name_str) => {
          let fun_name_Name = Name::name_only(fun_name_str)
          println("fun_name_Name = \{fun_name_Name}")
          if self.externals.find(fun_name_str)!=None{
            Let((self.new_temp(),@types.Type::Int),
              ExternalFunctionApplication(fun_name_str,array_params_Name),
              Unit)
          }else{
            let tmp = self.new_temp()
            println(tmp)
            let tmp_knf =Let((tmp,@types.Type::Int),
              Apply(fun_name_Name, array_params_Name),
              Unit)
            // knf_array.push(tmp_knf)
            // Var(tmp)
            tmp_knf
            
          }
        }
        _ => @util.die("函数名竟然不是Var类型")
      }
    }
    If(cond, then, els) => {
      let cond_left_name = self.new_temp()
      let cond_right_name = self.new_temp()
      match cond{
        Eq(left,right) => {
          let cond_left_knf=self.to_knf!(left)
          let tmp1 = Knf::Let((cond_left_name,@types.Type::Int),cond_left_knf,Knf::Unit)
          knf_array.push(tmp1)


          let cond_right_knf=self.to_knf!(right)
          let tmp2 = Knf::Let((cond_right_name,@types.Type::Int),cond_right_knf, Knf::Unit)
          knf_array.push(tmp2)

          println("提示: \{cond_left_name}")
          println("提示: \{tmp1}")
          println("提示: \{cond_right_name}")
          println("提示: \{tmp2}")
          println("提示knf_array: \{knf_array}")
        }
        // todo
        // _ =>{} 
      }
      let result = self.new_temp()
      Knf::Let(
        (result, @types.Type::Int),
        Knf::IfEq(cond_left_name, cond_right_name, self.to_knf!(then), self.to_knf!(els)),
        Knf::Unit
      )
    }
    
    Seq(ast_array)=>{
      let new_ast_array=[]
      for ast in ast_array{
        println("开始新的ast：\{ast}")
        let knf= self.to_knf!(ast)
        new_ast_array.push(knf)
      }
      Knf::Seq(new_ast_array)
    }
    _ => Knf::Unit
  }
}
let knf_array:Array[Knf]=[]
pub fn KnfEnv::seq_to_knf(self : KnfEnv, ast : @types.Syntax) -> Knf! {
  match ast{
    Seq(ast_array)=>{
      for one_ast in ast_array{
        let knf=self.to_knf!(one_ast)
        println(knf)
        knf_array.push(knf)
      }
      Knf::Seq(knf_array)
    }
    _ => Knf::Unit
  }
}