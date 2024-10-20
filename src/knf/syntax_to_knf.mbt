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
  match ast {
    // Trivial cases
    Var(name) => {
      Knf::Var(Name::from_string!(name))
      }
    Int(i) => Knf::Int(i)
    Prim(a, b, @types.Add,..) => {
      let a_name = self.new_temp()
      let b_name = self.new_temp()

      // let a_name = <a> in
      // let b_name = <b> in
      // a_name + b_name
      Knf::Let(
        (a_name,@types.Type::Int),
        self.to_knf!(a),
        Knf::Let((b_name,@types.Type::Int), self.to_knf!(b), Knf::Add(a_name, b_name)),
      )
    }
    Prim(a, b, @types.Mul,..) => {
      let a_name = self.new_temp()
      let b_name = self.new_temp()

      // let a_name = <a> in
      // let b_name = <b> in
      // a_name * b_name
      Knf::Let(
        (a_name, @types.Type::Int),
        self.to_knf!(a),
        Knf::Let((b_name,@types.Type::Int), self.to_knf!(b), Knf::Mul(a_name, b_name)),
      )
    }
    Let(name, value, body) =>
      // let name = <value> in
      // <body>
      // Knf::Let(name, to_knf(env, value), to_knf(env, body))
      match name{
        (name_str,name_type) => {
          Knf::Let(
            (Name::from_string!(name_str),@types.Type::Int), 
            self.to_knf!(value),
            self.to_knf!(body))
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
    _ => Knf::Unit
  }
}

// pub fn KnfEnv::to_knf(self : KnfEnv, ast : @types.Syntax) -> Knf! { // !Failure
//   match ast {
//       @types.Syntax::Seq(ast_array)=>{
//         for one_ast in ast_array{
//           match one_ast{
//             // Trivial cases
//               Var(name) => {
//                 Knf::Var(Name::from_string!(name))
//                 }
//               Int(i) => Knf::Int(i)
//               Prim(a, b, @types.Add,..) => {
//                 let a_name = self.new_temp()
//                 let b_name = self.new_temp()

//                 // let a_name = <a> in
//                 // let b_name = <b> in
//                 // a_name + b_name
//                 Knf::Let(
//                   (a_name,@types.Type::Int),
//                   self.to_knf!(a),
//                   Knf::Let((b_name,@types.Type::Int), self.to_knf!(b), Knf::Add(a_name, b_name)),
//                 )
//               }
//               Prim(a, b, @types.Mul,..) => {
//                 let a_name = self.new_temp()
//                 let b_name = self.new_temp()

//                 // let a_name = <a> in
//                 // let b_name = <b> in
//                 // a_name * b_name
//                 Knf::Let(
//                   (a_name, @types.Type::Int),
//                   self.to_knf!(a),
//                   Knf::Let((b_name,@types.Type::Int), self.to_knf!(b), Knf::Mul(a_name, b_name)),
//                 )
//               }
//               Let(name, value, body) =>
//                 // let name = <value> in
//                 // <body>
//                 // Knf::Let(name, to_knf(env, value), to_knf(env, body))
//                 match name{
//                   (name_str,name_type) => {
//                     Knf::Let(
//                       (Name::from_string!(name_str),@types.Type::Int), 
//                       self.to_knf!(value),
//                       self.to_knf!(body))
//                   }
//                 }

//               If(cond, then, els) => {
//                 let cond_name = self.new_temp()

//                 // let cond_name = <cond> in
//                 // if cond_name then <then> else <els>
//                 // Knf::Let(
//                 //   (cond_name,@types.Type::Bool),
//                 //   self.to_knf!(cond),
//                 //   Knf::IfEq(cond_name, then, self.to_knf!(els),Knf::Unit)
//                 // )
//                   Knf::Unit
//               _ => Knf::Unit
//               }
//             }
//           }
//           Knf::Unit
//     }
//     _ => {
//         @util.die("并非Seq")
//       }
//   }
// }