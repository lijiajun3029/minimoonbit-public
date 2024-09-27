# install third packages
moon login
moon update
moon add some_package # from moon.mod.json

git submodule update --init --recursive

# local test
moon test
moon test -v
moon run src/bin/main.mbt some_file.mbt
# moon run src/bin/main.mbt src/utils.mbt
# moon run src/bin/main.mbt test/test_src/ack.mbt

# dev


# remote test
git archive -o submit.zip HEAD