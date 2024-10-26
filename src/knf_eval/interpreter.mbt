struct KnfInterpreter {
  extern_fns : Map[String, (Array[Value]) -> Value]
  mut init_env : InterpreterLocalVars
}

pub typealias Name = @types.Name

pub typealias InterpreterLocalVars = @immut/hashmap.T[Name, Value]

pub enum Value {
  Unit
  Int(Int)
  Double(Double)
  Tuple(Array[Value])
  Array(Array[Value])
  ExternFn(String)
  Closure(@knf.FuncDef, Ref[InterpreterLocalVars])  // 闭包，保留本地变量
} derive(Show)

pub fn Value::op_equal(self : Value, other : Value) -> Bool {
  match (self, other) {
    (Unit, Unit) => true
    (Int(x), Int(y)) => x == y
    (Double(x), Double(y)) => x == y
    (Tuple(xs), Tuple(ys)) => xs == ys
    (Array(xs), Array(ys)) => xs == ys
    (ExternFn(x), ExternFn(y)) => x == y
    (Closure(_, _), Closure(_, _)) => false
    _ => false
  }
}

pub fn KnfInterpreter::new() -> KnfInterpreter {
  { extern_fns: Map::new(), init_env: InterpreterLocalVars::new() }
}

pub fn KnfInterpreter::add_extern_fn(
  self : KnfInterpreter,
  name : String,
  f : (Array[Value]) -> Value
) -> Unit {
  self.extern_fns.set(name, f)
  self.init_env = self.init_env.add(Name::name_only(name), ExternFn(name))
}

// 检索解释器本地变量
fn find(env : InterpreterLocalVars, name : Name) -> Value!Failure {
  env.find(name).or_error!(Failure("variable not found: \{name}"))
}

pub fn KnfInterpreter::eval_full(
  self : KnfInterpreter,
  expr : @knf.Knf
) -> Value!Failure {
  self.eval!(self.init_env, expr)
}

pub fn KnfInterpreter::eval(
  self : KnfInterpreter,
  env : InterpreterLocalVars,
  expr : @knf.Knf
) -> Value!Failure {
  // let mut all_env=env
  match expr {
    Unit => Unit
    Int(i) => Int(i)
    Double(d) => Double(d)
    Var(v) => find!(env, v)
    Neg(x) => {
      let x = find!(env, x)
      match x {
        Int(x) => Int(-x)
        _ => fail!("type mismatch, neg expects Int")
      }
    }
    Add(x, y) => {
      println("Add: \{x} \{y}")
      let x = find!(env, x)
      let y = find!(env, y)
      println("Add: \{x} \{y}")
      match (x, y) {
        (Int(x), Int(y)) => Int(x + y)
        _ => fail!("type mismatch, add expects Int")
      }
    }
    Sub(x, y) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Int(x), Int(y)) => Int(x - y)
        _ => fail!("type mismatch, sub expects Int")
      }
    }
    Mul(x, y) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Int(x), Int(y)) => Int(x * y)
        _ => fail!("type mismatch, mul expects Int")
      }
    }
    Div(x, y) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Int(x), Int(y)) => Int(x / y)
        _ => fail!("type mismatch, div expects Int")
      }
    }
    FNeg(x) => {
      let x = find!(env, x)
      match x {
        Double(x) => Double(-x)
        _ => fail!("type mismatch, fneg expects Double")
      }
    }
    FAdd(x, y) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Double(x), Double(y)) => Double(x + y)
        _ => fail!("type mismatch, fadd expects Double")
      }
    }
    FSub(x, y) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Double(x), Double(y)) => Double(x - y)
        _ => fail!("type mismatch, fsub expects Double")
      }
    }
    FMul(x, y) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Double(x), Double(y)) => Double(x * y)
        _ => fail!("type mismatch, fmul expects Double")
      }
    }
    FDiv(x, y) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Double(x), Double(y)) => Double(x / y)
        _ => fail!("type mismatch, fdiv expects Double")
      }
    }
    IfEq(x, y, e1, e2) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Int(x), Int(y)) =>
          if x == y {
            self.eval!(env, e1)
          } else {
            self.eval!(env, e2)
          }
        (Double(x), Double(y)) =>
          if x == y {
            self.eval!(env, e1)
          } else {
            self.eval!(env, e2)
          }
        _ => fail!("type mismatch, ifeq expects Int or Double")
      }
    }
    IfLe(x, y, e1, e2) => {
      let x = find!(env, x)
      let y = find!(env, y)
      match (x, y) {
        (Int(x), Int(y)) =>
          if x <= y {
            self.eval!(env, e1)
          } else {
            self.eval!(env, e2)
          }
        (Double(x), Double(y)) =>
          if x <= y {
            self.eval!(env, e1)
          } else {
            self.eval!(env, e2)
          }
        _ => fail!("type mismatch, ifle expects Int or Double")
      }
    }
    Let((name, _), e1, e2) => {
      println("提示: Let: name=\{name}, e1=\{e1}, e2=\{e2}")
      let v = self.eval!(env, e1)
      let new_env = env.add(name, v)
      // self.eval!(new_env, e2)
      match e2{
        Unit => v
        _ => self.eval!(new_env, e2)
      }
    }
    LetRec(f, e) => {
      println("提示：LetRec: f=\{f}; e=\{e}")
      // 由于我们没有使用连续语句，添加的函数定义会丢失
      let f_env = Ref::new(env)
      // println("test1")
      // let new_env = env.add(f.name, Closure(f, f_env))
      // println("test2")
      // f_env.val = new_env // 此处易无限递归溢出
      // println("提示：new_env = \{new_env}")
      
      // 添加到全局外部函数，饮鸩止渴
      // self.add_extern_fn(f.name.to_string(), ExternFn())
      // all_env = new_env

      // self.eval!(new_env, e)

      // 如果使用全局变量
      // Unit
      Closure(f, f_env)
      
    }
    Apply(f, xs) => {
      println("提示：Apply: f=\{f}; xs=\{xs}")
      println("提示：env = \{env}")
      println("提示：f = \{f}")
      let f = find!(env, f)
      println("提示：f = \{f}")
      match f {
        Closure(f, f_env) => {
          let mut new_env = f_env.val
          for i = 0; i < f.args.length(); i = i + 1 {
            let (x, _) = f.args[i]
            println("提示：x：\{x}")
            println("提示：xs[i]：\{xs[i]}")
            new_env = new_env.add(x, find!(env, xs[i]))
            println("提示：new_env = \{new_env}")
          }
          println("提示：new_env = \{new_env}")
          self.eval!(new_env, f.body)
        }
        ExternFn(name) => {
          let args = []
          for x in xs {
            args.push(find!(env, x))
          }
          let f = self.extern_fns
            .get(name)
            .or_error!(Failure("extern fn not found \{name}"))
          f(args)
        }
        _ => fail!("type mismatch, apply expects Closure or ExternFn")
      }
    }
    Tuple(xs) => {
      let vs = []
      for x in xs {
        vs.push(find!(env, x))
      }
      Tuple(vs)
    }
    LetTuple(xts, y, e) => {
      let mut new_env = env
      let y = find!(env, y)
      match y {
        Tuple(vs) => {
          let len = xts.length()
          if len != vs.length() {
            fail!("tuple size mismatch")
          }
          for i = 0; i < len; i = i + 1 {
            let (x, _) = xts[i]
            new_env = new_env.add(x, vs[i])
          }
        }
        _ => fail!("type mismatch, lettuple expects Tuple")
      }
      self.eval!(new_env, e)
    }
    Get(arr, idx) => {
      let arr = find!(env, arr)
      let idx = find!(env, idx)
      match (arr, idx) {
        (Array(arr), Int(idx)) => arr[idx]
        _ => fail!("type mismatch, get expects Array and Int")
      }
    }
    Put(arr, idx, v) => {
      let arr = find!(env, arr)
      let idx = find!(env, idx)
      let v = find!(env, v)
      match (arr, idx) {
        (Array(arr), Int(idx)) => arr[idx] = v
        _ => fail!("type mismatch, put expects Array and Int")
      }
      Unit
    }
    ExternalArray(_) => fail!("ExternalArray is not supported")
    ExternalFunctionApplication(name, args) => {
      println("提示：ExternalFunctionApplication：\{name}")
      let f = self.extern_fns
        .get(name)
        .or_error!(Failure("extern fn not found \{name}"))
      let argv = []
      for x in args {
        // let x_= self.eval!(env,x)
        argv.push(find!(env, x))
      }
      f(argv)
    }
    Seq(knf_array) => {
      // 评估入口, 但是body也会再次进入
      let mut current_env = env; // 保存当前的环境
      // let current_env = env; // 保存当前的环境
      let mut result = Unit
      for knf in knf_array{
        // println("\n重置的评估环境env：\{env}")
        // let result= self.eval!(env, knf)
        
        // println("\n重置的评估环境all_env：\{all_env}")
        // let tmp= self.eval!(all_env, knf)
        

        // 更新本地环境
        result= self.eval!(current_env, knf)
        println("更新前：\{current_env}")
        current_env = self.update_env(current_env, knf, result); // 更新环境
        println("更新后：\{current_env}")

        println("knf: \{knf} 's value: \{result}")
      }
      result
    }
  }
}

fn KnfInterpreter::update_env(
  self : KnfInterpreter,
  env: InterpreterLocalVars,
  knf: @knf.Knf,
  result: Value
) -> InterpreterLocalVars {
  match knf {
    Let((x, _), _, _) => {
      env.add(x, result) // 更新环境中的本地变量
    }
    LetRec(f, _) => {
      env.add(f.name, result) // 更新环境中的递归函数
    }
    _ => env // 其他情况保持环境不变
  }
}
