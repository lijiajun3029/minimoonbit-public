/// 类型检查
/// moonbit是一门静态类型检查编程语言。
fn new_tvar() -> @types.Type {
  //  Var(t=None)
  Var({val:None})
 }
 
// fn unify(t1: Ty, t2: Ty) -> Unit!TyErr {
//   let t1 = t1.repr()
//   let t2 = t2.repr()
//   if physical_equal(t1, t2) { return }
//   match (t1, t2) {
//     (Int, Int) | (Bool, Bool) => ()
//     (TVar(t=None) as tvar, ty) | (ty, TVar(t=None) as tvar) => {
//       check_occur!(tvar, ty)
//       tvar.t = Some(ty)
//     }
//     .. // handle the function, tuple, and array @types.Type  
//     _ => raise TyErr
//   }
// }
