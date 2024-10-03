## 计算test/test_src中token及其频次(辅助src/top.mbt收集minimoonbit编程语言的token)
`python test/script/token_list.py test/test_src/`
## output:
    ( 299
    ) 299
    ; 286
    + 223
    , 201
    = 192
    let 164
    { 162
    } 162
    : 116
    :: 13
    [ 132
    ] 132
    init  131
    fn  94
    -> 68
    Array 54
    . 51
    Double  45
    - 41
    if  34
    esle  34
    main  32
    Unit  27
    <= 26
    make  13
    * 12
    == 8
    // _ 38  // 缺省标识符
    // print_int等无效函数
    ...
    ...
    Total .mbt files in test/test_src processed: 32

## 使用pygments（综合观察两个脚本的输出，减少token遗漏）
`python test/script/token_list_pygments.py test/test_src/`  