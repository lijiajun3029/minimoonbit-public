/// The stage to be run next.
enum Stages {
  Parse
  Typecheck
  Knf
  KnfOpt
  Closure
  Asm
  Finished
} derive(Show, Eq, Compare)

fn Stages::from_string(s : String) -> Stages? {
  match s {
    "parse" => Some(Stages::Parse)
    "typecheck" => Some(Stages::Typecheck)
    "knf" => Some(Stages::Knf)
    "knf-opt" => Some(Stages::KnfOpt)
    "closure" => Some(Stages::Closure)
    "riscv" => Some(Stages::Asm)
    "finished" => Some(Stages::Finished)
    _ => None
  }
}

fn Stages::next(self : Stages) -> Stages {
  match self {
    Stages::Parse => Stages::Typecheck
    Stages::Typecheck => Stages::Knf
    Stages::Knf => Stages::KnfOpt
    Stages::KnfOpt => Stages::Closure
    Stages::Closure => Asm
    Stages::Asm => Stages::Finished
    Stages::Finished => Stages::Finished
  }
}

struct CompileStatus {
  mut curr_stage : Stages
  end_stage : Stages
  mut source_code : String?
  mut ast : @types.Syntax?
  // mut ast : Array[@types.Syntax?] // todo
  mut typechecked : @types.Syntax?
  knf_env : @knf.KnfEnv
  mut knf : @knf.Knf?
  mut opt_knf : @knf.Knf?
  mut closure_ir : @closure.Program?
  mut asm : Array[@riscv.AssemblyFunction]?
}

fn CompileStatus::initialize(
  start_stage : Stages,
  end_stage : Stages,
  file : String
) -> CompileStatus! {
  let v = CompileStatus::{
    curr_stage: start_stage,
    end_stage,
    source_code: None,
    ast: None,
    typechecked: None,
    knf_env: @knf.KnfEnv::new(externals()),
    knf: None,
    opt_knf: None,
    closure_ir: None,
    asm: None,
  }
  println(start_stage)
  match start_stage {
    Parse => v.source_code = Some(file)
    Typecheck => v.ast = Some(@types.Syntax::from_json!(@json.parse!(file)))  // moonbit编译器可以完成解析
    Knf => v.typechecked = Some(@types.Syntax::from_json!(@json.parse!(file)))
    KnfOpt => {
      v.knf = Some(@knf.Knf::from_json!(@json.parse!(file)))
      v.knf_env.init_counter_from_existing(v.knf.unwrap())
    }
    Closure => {
      v.opt_knf = Some(@knf.Knf::from_json!(@json.parse!(file)))
      v.knf_env.init_counter_from_existing(v.opt_knf.unwrap())
    }
    _ => fail!("invalid start stage")
  }
  v
}

/// Run the next stage of compilation. Returns true if the compilation is finished.
fn CompileStatus::step(self : CompileStatus) -> Bool!{
  if self.curr_stage >= self.end_stage {
    return true
  }
  match self.curr_stage {
    Parse => {
      println("\nstart parse")
      let source_code = self.source_code.unwrap()
      println(source_code)
      let tokens = []
      @lex.lex({ str: source_code, offset: 0, array: tokens })
      println(tokens)
      println("end lex")
      let (parsed, _) = @parser.parse_syntax(tokens[:]).unwrap()
      self.ast =Some(parsed)
      // self.ast =parsed
      // self.ast=[parsed]  // 可不可以返回一个Array[Syntax],如何返回一个Syntax
      println("生成ast：\{self.ast}")
      println("end parse\n")
      // Some(self.ast)
    }
    Typecheck => {
      println("\n\nstart typecheck")
      self.typechecked = Some(@typing.typing!(self.ast.unwrap()))
      println("生成typechecked：\{self.typechecked}")
      println("end typecheck")
    }
    Knf => {
      println("\nstart knf")
      let knf0 = self.knf_env.syntax_preprocess(self.typechecked.unwrap())
      let knf = self.knf_env.seq_to_knf!(knf0)
      self.knf = Some(knf)
      println("self.knf: \{self.knf}")
      println("end knf\n")
    }
    KnfOpt => {
      println("\nstart knf opt")
      let knf = self.knf.unwrap()
      // TODO: optimize
      self.opt_knf = Some(knf)
      println("end knf opt\n")
    }
    Closure => {
      let closure_ir = @closure.knf_program_to_closure(
        self.opt_knf.unwrap(),
        Map::from_iter(externals().iter()),
      )
      self.closure_ir = Some(closure_ir)
    }
    Asm => {
      let real_asm = @riscv.emit(@util.die("TODO"))
      self.asm = Some(real_asm)
    }
    Finished => ()
  }
  self.curr_stage = self.curr_stage.next()
  self.curr_stage >= self.end_stage
}

fn CompileStatus::output(self : CompileStatus, json : Bool) -> String {
  if json {
    match self.curr_stage {
      Parse => self.source_code.unwrap()
      Typecheck => @json.stringify(self.ast.unwrap().to_json())
      Knf => @json.stringify(self.typechecked.unwrap().to_json())
      KnfOpt => @json.stringify(self.knf.unwrap().to_json())
      Closure => @json.stringify(self.opt_knf.unwrap().to_json())
      Asm => @json.stringify(self.closure_ir.unwrap().to_json())
      Finished => @riscv.print_functions(self.asm.unwrap())
    }
  } else {
    match self.curr_stage {
      Parse => self.source_code.unwrap()
      Typecheck => self.ast.unwrap().to_string()
      Knf => self.typechecked.unwrap().to_string()
      KnfOpt => self.knf.unwrap().to_string()
      Closure => self.opt_knf.unwrap().to_string()
      Asm => self.closure_ir.unwrap().to_string()
      Finished => @riscv.print_functions(self.asm.unwrap())
    }
  }
}

fn main {
  let argv = @env.get_args()
  let mut file = None
  let knf_opt_iters = Ref::new(10)
  let knf_opt_inline_threshold = Ref::new(10)

  // Testing directives
  let json = Ref::new(false)
  let start_stage = Ref::new(Stages::Parse)
  let end_stage = Ref::new(Stages::Finished)
  let knf_interpreter = Ref::new(false)
  let closure_interpreter = Ref::new(false)
  let out_file = Ref::new("-")
  let print = Ref::new([])

  // 
  @ArgParser.parse(
    [
      (
        "--start-stage",
        "",
        @ArgParser.String(
          fn(s) {
            match Stages::from_string(s) {
              Some(stage) => start_stage.val = stage
              None => @util.die("Invalid stage")
            }
          },
        ),
        "Start stage",
      ),
      (
        "--end-stage",
        "",
        @ArgParser.String(
          fn(s) {
            match Stages::from_string(s) {
              Some(stage) => end_stage.val = stage
              None => @util.die("Invalid stage")
            }
          },
        ),
        "End stage",
      ),
      (
        "--knf-interpreter",
        "",
        @ArgParser.Set(knf_interpreter),
        "Run with KNF interpreter",
      ),
      (
        "--closure-interpreter",
        "",
        @ArgParser.Set(closure_interpreter),
        "Run with closure interpreter",
      ),
      (
        "--out-file",
        "-o",
        @ArgParser.String(fn(s) { out_file.val = s }),
        "Output file",
      ),
      ("--json", "", @ArgParser.Set(json), "Print results as JSON"),

      // Regular directives
      (
        "--print",
        "",
        @ArgParser.String(fn(s) { print.val = s.split(",").collect() }),
        "",
      ),
      (
        "--knf-opt-iters",
        "N",
        @ArgParser.String(
          fn(s) {
            let i = @strconv.parse_int?(s)
            match i {
              Ok(i) => knf_opt_iters.val = i
              Err(e) => @util.die("Invalid number")
            }
          },
        ),
        "Number of optimization iterations",
      ),
      (
        "--knf-opt-inline-threshold",
        "N",
        @ArgParser.String(
          fn(s) {
            let i = @strconv.parse_int?(s)
            match i {
              Ok(i) => knf_opt_inline_threshold.val = i
              Err(e) => @util.die("Invalid number")
            }
          },
        ),
        "Inline threshold for KNF optimization",
      ),
    ],
    fn(s) {
      if file.is_empty().not() {
        @util.die("multiple files are given")
      }
      file = Some(s)
    },
    "",
    argv,
  )

  // Configure pipeline
  if knf_interpreter.val {
    // 执行knf_interpreter（包含knf）
    end_stage.val = Stages::Knf
  }
  if closure_interpreter.val {
    end_stage.val = Stages::Closure
  }
  let stages_to_print = print.val.map(
    fn(s) {
      match Stages::from_string(s) {
        Some(stage) => stage
        None => @util.die("Invalid stage to print: \{s}")
      }
    },
  )

  // Input
  let file = if file.is_empty() {
    @util.die("no input file provided")
  } else {
    file.unwrap()
  }
  let contents = @fs.read_to_string(file)

  // Compilation
  let status = match
    CompileStatus::initialize?(start_stage.val, end_stage.val.next(), contents) {
    Ok(status) => status
    Err(e) => {
      println(e)
      @util.die("Initialization error")
    }
  }

  // Run stages
  while true {
    let stg = status.curr_stage
    let mut stop =false
    try {
       stop = status.step!()
    }catch{
        // @typing.TyErr(s) => println(s)
        _ => @util.die("捕获阶段异常")
    }
    if stages_to_print.contains(stg) {
      println("Stage: \{stg}")
      println(status.output(json.val))
    }
    if stop {
      break
    }
  }

  // Output
  if knf_interpreter.val {
    println("\nstart knf interpreter val")
    let knfi = @knf_eval.KnfInterpreter::new()
    // 添加解释器函数
    add_interpreter_fns(knfi)
    match knfi.eval_full?(status.knf.unwrap()) {
      Ok(knf_eval) => {
        // println("knf评估结果：")
        // println(knf_eval)
        ()
        }
      Err(Failure(e)) => {
        println(e)
        @util.die("KNF interpreter error")
      }
    }
    // println("end knf interpreter val\n")
  } else if closure_interpreter.val {
    let clsi = @closure_eval.ClosureInterpreter::new()
    add_closure_interpreter_fns(clsi)
    match clsi.eval_full?(status.closure_ir.unwrap()) {
      Ok(_) => ()
      Err(Failure(e)) => {
        println(e)
        @util.die("Closure interpreter error")
      }
    }
  } else {
    let out_string = status.output(json.val)
    if out_file.val == "-" {
      println(out_string)
    } else {
      @fs.write_to_string(out_file.val, out_string)
    }
  }
}
