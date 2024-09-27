# install third packages
moon login
moon update
moon add some_package # from moon.mod.json

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
