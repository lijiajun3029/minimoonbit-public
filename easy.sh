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

# local language debug
moon run test_language/main.mbt

# dev
# 解析
moon run src/bin/main.mbt -- --end-stage parse test/test_src/ack.mbt

# test simple src
moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/expression.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/if_else.mbt

# test cases(auto test all on local machine)
# 语法解析
moon run src/bin/main.mbt -- --end-stage parse test/test_cases/parsing/arith.mbt

# 类型检查
moon run src/bin/main.mbt -- --end-stage typecheck test/test_cases/typing/arith.mbt

# 快速测试&提交
./test/scripts/faster_test.sh  test/test_cases/typing/
./test/scripts/faster_test_all.sh
# remote compiler test(仅仅打包Head提交)
git archive -o submit.zip HEAD