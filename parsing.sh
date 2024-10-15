#!/bin/bash

for file in "./test/test_cases/typing"/*; do
    filename=$(basename "$file")
    echo "$filename"
    moon run ./src/bin/main.mbt -- --end-stage parse $file >information.txt 2>error_log.txt
    if [ $? -eq 0 ]; then
        echo "$file_name :AC"
    else
        echo "$file_name :RE"
    fi
done
