# install third packages
# moon login  # 登陆你的账户
moon update   # 更新包注册表索引
moon add package_name # from moon.mod.json

git submodule update --init --recursive

# local compiler test
moon test # 扫描整个模块，识别并运行所有内联测试以及以_test.mbt结尾的文件
moon test -v
moon run src/bin/main.mbt some_file.mbt
# moon run src/bin/main.mbt test/test_src/ack.mbt

# remote compiler test
git archive -o submit.zip HEAD

# local language debug
 moon run test_language/main.mbt

# dev
# 解析
moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/expression.mbt
moon run src/bin/main.mbt -- --end-stage parse test/test_src/ack.mbt

# todo
moon run src/bin/main.mbt -- --end-stage parse test/test_simple_src/if_else.mbt 