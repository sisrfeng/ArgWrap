" Copyright (c) 2014 Alex Yatskov <alex@foosoft.net>

call argwrap#initSetting('line_prefix'        , '')
call argwrap#initSetting('padded_braces'      , '')

call argwrap#initSetting('tail_comma'         , 0)
call argwrap#initSetting('tail_comma_braces'  , '')

call argwrap#initSetting('tail_indent_braces' , '')
call argwrap#initSetting('wrap_closing_brace' , 1)

call argwrap#initSetting('comma_first'        , 0)
call argwrap#initSetting('comma_first_indent' , 0)

call argwrap#initSetting('filetype_hooks'     , {})
call argwrap#initSetting('php_smart_brace'    , 0)

com!   ArgWrap call argwrap#toggle()

nno    <silent> <Plug>(ArgWrapToggle)     :call argwrap#toggle() <BAR>
                                         \silent! call repeat#set("\<Plug>(ArgWrapToggle)")<CR>
