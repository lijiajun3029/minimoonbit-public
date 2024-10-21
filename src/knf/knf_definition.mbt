pub typealias Name = @types.Name

pub typealias Type = @types.Type

// Let、LetRec、LetTuple最后一个参数用来支持连续语句
pub enum Knf {
  Unit
  Int(Int)
  Double(Double)
  Neg(Name)
  Add(Name, Name)
  Sub(Name, Name)
  Mul(Name, Name)
  Div(Name, Name)
  FNeg(Name)
  FAdd(Name, Name)
  FSub(Name, Name)
  FMul(Name, Name)
  FDiv(Name, Name)
  IfEq(Name, Name, Knf, Knf)  // 如果等于
  IfLe(Name, Name, Knf, Knf)  // 如果小于等于
  Let((Name, Type), Knf, Knf)   // 最后一个参数用来支持连续语句
  Var(Name)
  LetRec(FuncDef, Knf)  // 最后一个参数用来支持连续语句
  Apply(Name, Array[Name])
  Tuple(Array[Name])
  LetTuple(Array[(Name, Type)], Name, Knf)  // 最后一个参数用来支持连续语句
  Get(Name, Name)
  Put(Name, Name, Name)
  ExternalArray(Name)
  ExternalFunctionApplication(String, Array[Name])
  Seq(Array[Knf])   // 饮鸩止渴
} derive(Show, Eq)

pub struct FuncDef {
  name : Name
  ty : Type
  args : Array[(Name, Type)]
  body : Knf
} derive(Show, Eq)
