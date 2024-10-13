#!/bin/bash

for file in "./test/typing"/*; do
    moon run ./src/bin/main.mbt -- --end-stage parse $file
    read -n 1 -p "whether continue? [y/n]: " ans
    if 
        test $ans = 'y'
    then
        continue
    else
        break
    fi
done