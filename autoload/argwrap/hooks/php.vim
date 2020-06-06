function! s:dealWithMethodArguments(container) abort " {{{
  if a:container.suffix !~ '\v^\)'
    return 0
  endif

  if a:container.prefix !~? '\v^%(public|protected|private)\s+function\s+\S+\s*\($'
    return 0
  endif

  return 1
endfunction " }}}

function! argwrap#hooks#php#post_wrap(range, container, arguments) abort " {{{
  if argwrap#getSetting('php_smart_brace', 0)
    call s:fixMethodOpeningBraceAfterWrap(a:range, a:container, a:arguments)
  endif
endfunction  " }}}

function! argwrap#hooks#php#post_unwrap(range, container, arguments) abort " {{{
  if argwrap#getSetting('php_smart_brace', 0)
    call s:fixMethodOpeningBraceAfterUnwrap(a:range, a:container, a:arguments)
  endif
endfunction  " }}}

function! s:fixMethodOpeningBraceAfterWrap(range, container, arguments) abort " {{{
  if !s:dealWithMethodArguments(a:container)
    return
  endif

  let l:lineEnd = a:range.lineEnd + len(a:arguments)

  " Add 1 more line if the brace is also wrapped
  " TODO define default values on the plugin level so that extension can
  " request an option value without having to pass them all as argument or
  " having to duplicate the default value
  if 0 != argwrap#getSetting('wrap_closing_brace', 1)
    let l:lineEnd += 1
  endif

  if getline(l:lineEnd + 1) =~ '\v^\s*\{'
    execute printf('undojoin | normal! %dGJ', l:lineEnd)
  endif
endfunction " }}}

function! s:fixMethodOpeningBraceAfterUnwrap(range, container, arguments) abort " {{{
  if !s:dealWithMethodArguments(a:container)
    return
  endif

  if a:container.suffix !~ '\v^\)\s*\{'
    return
  endif

  " +1 to get the position after the closing parenthesis
  let l:col = stridx(getline(a:range.lineStart), a:container.suffix) + 1

  execute printf("undojoin | normal! %dG0%dlct{\<CR>", a:range.lineStart, l:col)
endfunction " }}}

" vim: ts=2 sw=2 et fdm=marker
