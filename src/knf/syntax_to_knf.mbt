pub typealias LocalEnv = @immut/hashmap.T[String, Type]

struct KnfEnv {
  mut counter : Int
  externals : @immut/hashmap.T[String, Type]
}

pub fn KnfEnv::new(externals : @immut/hashmap.T[String, Type]) -> KnfEnv {
  { counter: 1, externals }
}

pub fn KnfEnv::init_counter_from_existing(
  self : KnfEnv,
  existing : Knf
) -> Unit {
  self.counter = knf_max_counter(existing) + 1
}

fn KnfEnv::new_temp(self : KnfEnv) -> Name {
  let temp = Name::slot_only(self.counter)
  self.counter += 1
  temp
}

fn KnfEnv::new_named_temp(self : KnfEnv, name : Name) -> Name {
  let counter = self.counter
  self.counter += 1
  { ..name, slot: counter }
}

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
      let array_params_Name=[]
      for param in array_params{
        // 参数先to_knf,递归调用
        
        // 参数绑定变量名
        let tmp = self.new_temp()
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
            knf_array.push(tmp_knf)
            Var(tmp)
            
          }
        }
        _ => @util.die("函数名竟然不是Var类型")
      }
    }
    If(cond, then, els) => {
      let cond_name = self.new_temp()

      // let cond_name = <cond> in
      // if cond_name then <then> else <els>
      // Knf::Let(
      //   (cond_name,@types.Type::Bool),
      //   self.to_knf!(cond),
      //   Knf::IfEq(cond_name, then, self.to_knf!(els),Knf::Unit)
      // )
      Knf::Unit
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
      // Knf::Unit
    }
    _ => Knf::Unit
  }
}