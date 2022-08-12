" Copyright (c) 2014 Alex Yatskov <alex@foosoft.net>

call wrapA#initCfg('line_prefix'        , '')
call wrapA#initCfg('padded_braces'      , '')

call wrapA#initCfg('tail_comma'         , 0)
call wrapA#initCfg('tail_comma_braces'  , '')

call wrapA#initCfg('tail_indent_braces' , '')
call wrapA#initCfg('wrap_closing_brace' , 1)

call wrapA#initCfg('comma_first'        , 0)
call wrapA#initCfg('comma_first_indent' , 0)

call wrapA#initCfg('filetype_hooks'     , {})
call wrapA#initCfg('php_smart_brace'    , 0)

com!   wrapA call wrapA#toggle()

nno    <silent> <Plug>(wrapAToggle)     :call wrapA#toggle() <BAR>
                                         \silent! call repeat#set("\<Plug>(wrapAToggle)")<CR>
