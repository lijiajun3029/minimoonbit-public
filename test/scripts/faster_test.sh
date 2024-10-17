#!/bin/bash
# example: ./test/scripts/faster_test.sh  test/test_cases/parsing/

if [ -z "$1" ]; then  
  echo "Usage: $0 <path_to_directory_or_file>"  
  exit 1  
fi

for file in "$1"/*; do
    filename=$(basename "$file")
    moon run ./src/bin/main.mbt -- --end-stage parse $file >test/output/information.txt 2>test/output/error_log.txt
    if [ $? -eq 0 ]; then
        echo "$filename :AC"
    else
        echo "$filename :RE"
    fi
done
