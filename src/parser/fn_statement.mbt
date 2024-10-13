fn fn_statement(tokens: ArrayView[@lex.Token]) -> Option[(@types.Syntax, ArrayView[@lex.Token])] {
    ptoken(
      fn {
        Fn => {
          let curent_token_number=parser_context.token_length-tokens.length()
          println("FN curent_token_number: \{curent_token_number}")
          let {token_number,line,column_start,column_end}:@lex.TokenPosition = @lex.token_postion_array[curent_token_number]
          println("FN column_start: \{column_start}")
          if parser_context.is_top_level{
            if column_start==1{
              true
            }else{
              println("顶级未左对齐")
              false
            }
          }else{
            true
          }
        }
        _ => false
      }
    )
    .and(
      ptoken(
        fn {
        Fun_name(_) => {
          parser_context.is_main=false
          println("11")
          true
        }
        _ => false
      })
      .or(
        ptoken(
        fn {
          Main =>{
            println("main function")
            parser_context.is_main=true
            println(parser_context.is_main)
            true
          }
          _ => false
        })
      )
      .map(fn {
        Fun_name(fun_name) => fun_name  // 中间解析,可以简化最终解析
        _  => "main"
      })
    )
    .and(
        (if parser_context.is_main{
          // parser_context.is_main=false
          println("1 main lparen \{parser_context}")
          lparen_not
          // lparen_skip
        }else{
          println("1 lparen \{parser_context}")
          lparen
        })
        .and(
            // 解析参数列表，可以是空或一个或多个参数 
            ptoken(fn { 
                Identifier(_) => true
                _ => false 
            }).map(fn {
                Identifier(arg_name) =>{
                   println("test order")
                   arg_name
                   }
            })
            .and(colon)
            .and(parse_type)
            .map(fn { ((arg_name, _), arg_type) => (arg_name,arg_type) })   // 参数类型,中间解析,可以简化最终解析
            .and(     // todo 目前函数定义都是无参数的，此处支持参数匹配问题待解决
                comma
                // .or(rparen)
            )
            // .map(fn { (param, _) => param })
            .many()
        )
        .and(
          (if parser_context.is_main{
            println("2 main rparen \{parser_context}")
            rparen_not
            // rparen_skip
          }else{
            println("2 rparen \{parser_context}")
            rparen
          })
        )
    )
    .and(
      // 可以缺省一次，必须一起跳过，此处存在bug，可以构造ptoken_skip2,内支持两个断言函数
      ptoken_skip(fn {
          Arrow => true
          _ => false
      }).and(
        ptoken_skip(fn { 
                Colon => true
                _ => false 
            }).and(parse_type_skip)
      ).map(fn{
        (_,(_,ty)) => ty
      })
    )
    .and(block)// 解析函数体
    .and(semicolon)
    .map(fn {
        // ((((_,fun_name), ((_,array_params),_)),ty), body)
        (((((_,fun_name), ((_,array_params),_)),ty), body),_)
        => {
          let params=[]
          for param in array_params{
            params.push(param.0)
          }
          let fundef :@types.Fundef={name:(fun_name,ty), args:params, body:body}
          @types.Syntax::LetRec(fundef, @types.Syntax::Unit)
        }
        // (_,body)=>{
        //   let params=[]
        //   let fundef :@types.Fundef={name:("main",@types.Type::Unit), args:params, body:body}
        //   @types.Syntax::LetRec(fundef, @types.Syntax::Unit)
        // }
    })
    .parse(tokens)
}