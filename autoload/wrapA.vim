"\ helper
    fun! wrapA#Range_ok_01(a_range)
        return len(a:a_range) > 0
        \&& !(  a:a_range.lineStart == 0
                \&& a:a_range.colStart == 0
                \|| a:a_range.lineEnd == 0
                \&& a:a_range.colEnd == 0
            \)
    endf

    fun! wrapA#Compare_Ranges(range1, range2)
        let [l:buffer, line_nuM, l:col, l:offset] = getpos('.')

        let l:lineDiff1 = a:range1.lineStart - line_nuM
        let l:colDiff1  = a:range1.colStart - l:col
        let l:lineDiff2 = a:range2.lineStart - line_nuM
        let l:colDiff2  = a:range2.colStart - l:col

        if l:lineDiff1 < l:lineDiff2
            return 1
        elseif l:lineDiff1 > l:lineDiff2
            return -1
        elseif l:colDiff1 < l:colDiff2
            return 1
        elseif l:colDiff1 > l:colDiff2
            return -1
        el
            return 0
        en
    endf

    fun! wrapA#Find_Range(braces)
        let l:_filter =  'synIDattr(synID(line("."), col("."), 0), "name") =~? "string"'
        let [l:lineStart, l:colStart] = searchpairpos(
                                                \ a:braces[0],
                                                \ '',
                                                \ a:braces[1],
                                                \ 'Wnb',
                                                \ _filter,
                                            \ )

        let [l:lineEnd, l:colEnd] =     searchpairpos(
                                                \ a:braces[0],
                                                \ '',
                                                \ a:braces[1],
                                                \ 'Wnc',
                                                \ _filter,
                                            \ )

        return {
            \ 'lineStart' :  l:lineStart ,
            \ 'colStart'  :  l:colStart  ,
            \ 'lineEnd'   :  l:lineEnd   ,
            \ 'colEnd'    :  l:colEnd    ,
        \ }
    endf

    fun! wrapA#Find_Closest_Range()
        let l:ranges = []
        for l:braces in [
                    \ ['(', ')']   ,
                    \ ['\[', '\]'] ,
                    \ ['{', '}']   ,
                \ ]

            let l:a_range = wrapA#Find_Range(braces)
            if wrapA#Range_ok_01(l:a_range)
                call add(l:ranges, l:a_range)
            en
        endfor

        if len(l:ranges) == 0
            return {}
        el
            return sort(l:ranges, 'wrapA#Compare_Ranges')[0]
        en
    endf

    fun! wrapA#Get_Arg_Text_Here(a_range, linePrefix)
        " echom "71 行 linePrefix是" a:linePrefix
        " vim里面是¿\¿
        let l:text = ''
        let l:trimPattern = printf('\m^\s*\(.\{-}\%%(%s\)\?\)\s*$', escape(a:linePrefix, '\$.*^['))

        for l:lineIndex in range(a:a_range.lineStart, a:a_range.lineEnd)
            let l:lineText = getline(l:lineIndex)

            let l:Focus_Start = 0
            if l:lineIndex == a:a_range.lineStart
                let l:Focus_Start = a:a_range.colStart
            en

            let l:Focus_End = strlen(l:lineText)
            if l:lineIndex == a:a_range.lineEnd
                let l:Focus_End = a:a_range.colEnd - 1
            en

            if l:Focus_Start < l:Focus_End
                let l:Focus_ = l:lineText[l:Focus_Start : l:Focus_End - 1]
                let l:Focus_ = substitute(l:Focus_, l:trimPattern, '\1', '')
                if stridx(l:Focus_, a:linePrefix) == 0
                    let l:Focus_ = l:Focus_[len(a:linePrefix):]
                en
                let l:Focus_ = substitute(l:Focus_, ',$', ', ', '')
                let l:text .= l:Focus_
            en
        endfor

        return l:text
    endf

    fun! wrapA#updateScope(stack, char)
        let l:pairs = {'"': '"', '''': '''', ')': '(', ']': '[', '}': '{'}
        let l:length = len(a:stack)

        if l:length > 0 && get(l:pairs, a:char, '') == a:stack[l:length - 1]
            call remove(a:stack, l:length - 1)
        elseif index(values(l:pairs), a:char) >= 0
            call add(a:stack, a:char)
        en
    endf

    fun! wrapA#trimArgument(text)
        let l:trim = substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
        let l:trim = substitute(l:trim, '\([:=]\)\s\{2,}', '\1 ', '')
        return substitute(l:trim, '\s\{2,}\([:=]\)', ' \1', '')
    endf

    fun! wrapA#Focus_Args_Here(text)
        let l:text = substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')

        let l:stack = []
        let l:args = []
        let l:argument = ''

        if len(l:text) > 0
            for l:index in range(strlen(l:text))
                let l:char = l:text[l:index]
                call wrapA#updateScope(l:stack, l:char)

                if len(l:stack) == 0 && l:char == ','
                    let l:argument = wrapA#trimArgument(l:argument)
                    if len(l:argument) > 0
                        call add(l:args, l:argument)
                    en
                    let l:argument = ''
                el
                    let l:argument .= l:char
                en
            endfor

            let l:argument = wrapA#trimArgument(l:argument)
            if len(l:argument) > 0
                call add(l:args, l:argument)
            en
        en

        return l:args
    endf

    fun! wrapA#Focus_Here(a_range)
        let l:textStart = getline(a:a_range.lineStart)
        let l:textEnd = getline(a:a_range.lineEnd)

        let l:indent = matchstr(l:textStart, '\s*')
        let l:prefix = l:textStart[strlen(l:indent) : a:a_range.colStart - 1]
        let l:suffix = l:textEnd[a:a_range.colEnd - 1:]

        return {'indent': l:indent, 'prefix': l:prefix, 'suffix': l:suffix}
    endf

    fun! wrapA#wrapHere(
             \ a_range,
             \ here,
             \ args,
             \ wrapBrace,
             \ tailComma,
             \ tailCommaBraces,
             \ tailIndentBraces,
             \ linePrefix,
             \ commaFirst,
             \ commaFirstIndent,
            \ )

        let l:arg_num =  len(a:args)
        let line_nuM =  a:a_range.lineStart
        let l:prefix   =  a:here.prefix[ len(a:here.prefix) - 1 ]

        call setline(line_nuM,  a:here.indent . a:here.prefix)

        for l:index in range(l:arg_num)
            let l:last = l:index == l:arg_num - 1
            let l:first = l:index == 0
            let l:text = ''

            if a:commaFirst
                let l:text .= a:here.indent . a:linePrefix
                if !l:first
                    let l:text .= ', '
                end
                let l:text .= a:args[l:index]
            el
                let l:text .= a:here.indent . a:linePrefix . a:args[l:index]
                " echom "a:args 是: "   a:args
                " echom "l:index 是: "   l:index
                " echom "a:args[l:index] 是: "   a:args[l:index]
                " echom "l:text 是: "   l:text

                if  !l:last
                        let l:text .= ','
                el
                    if  a:tailComma    ||   a:tailCommaBraces =~ l:prefix
                        let l:text .= ','
                    en
                en
            en

            if l:last && !a:wrapBrace
                let l:text .= a:here.suffix
            en

            call append(line_nuM, l:text)

            " 处理indent
                " https://github.com/FooSoft/vim-wrapA/pull/26/files
                " 为了对齐得更好看:
                " 这2行:
                    " let line_nuM += 1
                    " silent! exec printf('%s>', line_nuM)
                " 变成 (开始):
                    if a:linePrefix != ''
                    " 因为有'/'等prefix, 如果arg1没换行, 就报错
                        " 下一行 死板地indent一次:
                        let line_nuM += 1
                        silent! exec printf('%s>', line_nuM)
                                        " 行号>>
                                        " Example
                                            " 233>>
                                            " 666>>
                    else
                        if l:first
                            norm! Jx
                                " 第一个arg此前已被换行, 现在取消换行
                            let l:indent = repeat(" ", getcurpos()[2] - 1)

                            " " 处理python里的self被conceal的情况:
                            " 不好搞:
                            " if getline(line_nuM) =~ 'self\.'
                            "     let l:indent = repeat(" ", getcurpos()[2] - 1 - 4)
                            " en
                        else
                            let line_nuM += 1
                            call setline(
                                        \ line_nuM,
                                        \ substitute(
                                                    \ getline(line_nuM),
                                                    \ "^ *",
                                                    \ l:indent,
                                                    \ "",
                                                    \ ),
                                        \ )


                            " " 处理python里的self被conceal的情况:
                            " 不好搞:
                            " if getline(line_nuM) =~ 'self\.'
                            "     let l:indent = repeat(" ", getcurpos()[2] - 1 - 4)
                            " en

                        endif
                    endif

                " 变成 (有bug的尝试):
                    " if a:wrapBrace
                    " " if !a:wrapBrace
                    "     " 如果Brace wrapping disabled:
                    "     "     Foo(
                    "     "         wibble,
                    "     "         wobble,
                    "     "         wubble)
                    "     if l:first
                    "         " norm! Jx
                    "             " 第一个arg此前已被换行, 现在取消换行
                    "         let l:indent = repeat(" ", getcurpos()[2] - 1)
                    "         if a:linePrefix
                    "         "     echom '删掉prefix'
                    "             norm! x
                    "         en
                    "     else
                    "         let line_nuM += 1
                    "         call setline(
                    "                     \ line_nuM,
                    "                     \ substitute(
                    "                                 \ getline(line_nuM),
                    "                                 \ "^ *",
                    "                                 \ l:indent,
                    "                                 \ "",
                    "                                 \ ),
                    "                     \ )
                    "     endif
                    " else
                    "     let line_nuM += 1
                    "     silent! exec printf('%s>', line_nuM)
                    "                     " 行号>>
                    "                     " Example
                    "                         " 233>>
                    "                         " 666>>
                    " endif

                " 变成 (结束)



            if l:first && a:commaFirstIndent
                let width = &l:shiftwidth
                let &l:shiftwidth = 2
                silent! exec printf('%s>', line_nuM)
                let &l:shiftwidth = l:width
            en
        endfor




        if a:wrapBrace
            call append(  line_nuM,
                        \ a:here.indent . a:linePrefix . a:here.suffix,
                        \ )
            if a:tailIndentBraces =~ l:prefix
                " tailIndentBraces作用:
                        "  enabled:
                        "     Foo(
                        "         wibble,
                        "         wobble,
                        "         wubble
                        "         ¿)¿

                        " disabled:
                        "     Foo(
                        "         wibble,
                        "         wobble,
                        "         wubble
                            " )

                let l:indent = repeat(" ", getcurpos()[2] - 2)
                let line_nuM += 1
                call setline(
                            \ line_nuM,
                            \ substitute(
                                        \ getline(line_nuM),
                                        \ "^ *",
                                        \ l:indent,
                                        \ "",
                                        \ ),
                            \ )

                " silent! exec printf('%s>', line_nuM + 1)
            en

            "
        en
    endf

    fun! wrapA#unwrapHere(a_range, here, args, padded)
        let l:brace = a:here.prefix[strlen(a:here.prefix) - 1]
        if stridx(a:padded, l:brace) == -1
            let l:padding = ''
        el
            let l:padding = ' '
        en

        let l:text = a:here.indent . a:here.prefix . l:padding . join(a:args, ', ') . l:padding . a:here.suffix
        call setline(a:a_range.lineStart, l:text)
        exec printf('silent %d,%dd_', a:a_range.lineStart + 1, a:a_range.lineEnd)
    endf


    " cfg
        fun! wrapA#getCfg(name)
            let l:bName = 'b:wrapA_' . a:name
            let l:gName = 'g:wrapA_' . a:name

            return  exists(l:bName)
                \ ? {l:bName}
                \ : {l:gName}
        endf

        fun! wrapA#initCfg(name, value) abort
            let l:setting = 'g:wrapA_' . a:name

            if !exists(l:setting)  | let {l:setting} = a:value  | en
        endf

fun! wrapA#toggle()
    let l:linePrefix       =  wrapA#getCfg('line_prefix')
    let l:padded           =  wrapA#getCfg('padded_braces')
    let l:tailComma        =  wrapA#getCfg('tail_comma')
    let l:tailCommaBraces  =  wrapA#getCfg('tail_comma_braces')
    let l:tailIndentBraces =  wrapA#getCfg('tail_indent_braces')
    let l:wrapBrace        =  wrapA#getCfg('wrap_closing_brace')
    let l:commaFirst       =  wrapA#getCfg('comma_first')
    let l:commaFirstIndent =  wrapA#getCfg('comma_first_indent')

    let l:a_range = wrapA#Find_Closest_Range()
    if !wrapA#Range_ok_01(l:a_range)  | return  | en

    let l:arg_text = wrapA#Get_Arg_Text_Here(l:a_range , l:linePrefix)
    let l:args     = wrapA#Focus_Args_Here(l:arg_text)
    if len(l:args) == 0  | return  | en

    let l:here = wrapA#Focus_Here(l:a_range)

    if l:a_range.lineStart == l:a_range.lineEnd
    " 一行变多行
        call wrapA#hooks#execute(
                    \ 'pre_wrap',
                    \ l:a_range,
                    \ l:here,
                    \ l:args,
                   \ )

        call wrapA#wrapHere(
                \ l:a_range          ,
                \ l:here             ,
                \ l:args             ,
                \ l:wrapBrace        ,
                \ l:tailComma        ,
                \ l:tailCommaBraces  ,
                \ l:tailIndentBraces ,
                \ l:linePrefix       ,
                \ l:commaFirst       ,
                \ l:commaFirstIndent ,
             \ )

        call wrapA#hooks#execute(
                    \ 'post_wrap',
                    \ l:a_range,
                    \ l:here,
                    \ l:args,
                   \ )
    el  " 多变1
        call wrapA#hooks#execute('pre_unwrap', l:a_range, l:here, l:args)

        call wrapA#unwrapHere(
                 \ l:a_range,
                 \ l:here,
                 \ l:args,
                 \ l:padded,
                \ )

        call wrapA#hooks#execute('post_unwrap', l:a_range, l:here, l:args)
    en
endf

" Copyright (c) 2014 Alex Yatskov <alex@foosoft.net>

