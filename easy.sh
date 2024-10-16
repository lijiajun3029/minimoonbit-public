# install third packages
# moon login  # 登陆你的账户
# 安装依赖
moon update   # 更新包注册表索引
moon add package_name # from moon.mod.json
moon install

git submodule update --init --recursive

# local compiler test
moon test # 扫描整个模块，识别并运行所有内联测试以及以_test.mbt结尾的文件
moon test -v
moon run src/bin/main.mbt some_file.mbt
# moon run src/bin/main.mbt test/test_src/ack.mbt

# remote compiler test(仅仅打包Head提交)
git archive -o submit.zip HEAD

# local language debug
moon run test_language/main.mbt

# dev
# 解析
moon run src/bin/main.mbt -- --end-stage parse test/test_src/ack.mbt

# test simple src
moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/expression.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/if_else.mbt

# test cases(todo test all)(auto test on local machine)
# AC
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/arith.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/ident.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/numbers.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/global_let.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/nested_fns.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/very_deep.mbt

moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/_neg_ident.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/_neg_ident2.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/_neg_no_semicolon.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/_neg_top_level_not_aligned.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/_neg_main_no_paren.mbt


# 类型检查
moon run src/bin/main.mbt -- --end-stage typecheck test/test_cases/typing/arith.mbt
moon run src/bin/main.mbt -- --end-stage typecheck test/test_cases/typing/untyped_inner_fn.mbt
moon run src/bin/main.mbt -- --end-stage typecheck test/test_cases/typing/landins_knot.mbt

moon run src/bin/main.mbt -- --end-stage typecheck test/test_cases/typing/_neg_self.mbt 