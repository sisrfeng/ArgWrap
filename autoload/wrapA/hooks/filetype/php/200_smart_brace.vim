function! s:dealWithMethodArgs(here) abort " {{{
    if a:here.suffix !~ '\v^\)'
        return 0
    endif

    if a:here.prefix !~? '\v^%(public|protected|private)(\s+static)?\s+function\s+\S+\s*\($'
        return 0
    endif

    return 1
endfunction " }}}

function! s:fixMethodOpeningBraceAfterWrap(range, here, args) abort " {{{
    if !s:dealWithMethodArgs(a:here)
        return
    endif

    let l:lineEnd = a:range.lineEnd + len(a:args)

    " Add 1 more line if the brace is also wrapped
    if 0 != wrapA#getCfg('wrap_closing_brace')
        let l:lineEnd += 1
    endif

    if getline(l:lineEnd + 1) =~ '\v^\s*\{'
        execute printf('undojoin | normal! %dGJ', l:lineEnd)
    endif
endfunction " }}}

function! s:fixMethodOpeningBraceAfterUnwrap(range, here, args) abort " {{{
    if !s:dealWithMethodArgs(a:here)
        return
    endif

    if a:here.suffix !~ '\v^\).*\{\s*$'
        return
    endif

    execute printf("undojoin | normal! %dG$F{gelct{\<CR>", a:range.lineStart)
endfunction " }}}

function! wrapA#hooks#filetype#php#200_smart_brace#pre_wrap(range, here, args) abort " {{{
    " Do nothing but prevent the file to be loaded more than once
    " When calling an autoload function that is not define, the script that
    " should contain it is sourced every time the function is called
endfunction  " }}}

function! wrapA#hooks#filetype#php#200_smart_brace#pre_unwrap(range, here, args) abort " {{{
    " Do nothing but prevent the file to be loaded more than once
    " When calling an autoload function that is not define, the script that
    " should contain it is sourced every time the function is called
endfunction  " }}}

function! wrapA#hooks#filetype#php#200_smart_brace#post_wrap(range, here, args) abort " {{{
    if wrapA#getCfg('php_smart_brace')
        call s:fixMethodOpeningBraceAfterWrap(a:range, a:here, a:args)
    endif
endfunction  " }}}

function! wrapA#hooks#filetype#php#200_smart_brace#post_unwrap(range, here, args) abort " {{{
    if wrapA#getCfg('php_smart_brace')
        call s:fixMethodOpeningBraceAfterUnwrap(a:range, a:here, a:args)
    endif
endfunction  " }}}

