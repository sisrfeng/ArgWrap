function! s:loadGlobalHooks() abort " {{{
    if !exists('g:wrapA_global_hooks')
        let g:wrapA_global_hooks = []

        for hook in globpath(&runtimepath, 'autoload/wrapA/hooks/*.vim', 0, 1)
            let l:filename = matchstr(hook, '\vhooks/\zs.+\ze\.vim$')

            call add(g:wrapA_global_hooks, printf('wrapA#hooks#%s', l:filename))
        endfor
    endif

    return g:wrapA_global_hooks
endfunction " }}}

function! s:loadFiletypeHooks(filetype) abort " {{{
    if !exists('g:wrapA_filetype_hooks.'.a:filetype)
        let g:wrapA_filetype_hooks[a:filetype] = []
        let l:hooks = g:wrapA_filetype_hooks[a:filetype]

        for filetypeHook in globpath(&runtimepath, 'autoload/wrapA/hooks/filetype/*/*.vim', 0, 1)
            let l:filetype = matchstr(filetypeHook, '\vhooks/filetype/\zs.+\ze/.+\.vim$')
            let l:filename = matchstr(filetypeHook, '\vhooks/filetype/.+/\zs.+\ze\.vim$')

            call add(l:hooks, printf('wrapA#hooks#filetype#%s#%s', l:filetype, l:filename))
        endfor
    endif

    return g:wrapA_filetype_hooks[a:filetype]
endfunction " }}}

function! s:load() abort " {{{
    if !exists('b:wrapA_hooks')
        let b:wrapA_hooks = s:loadGlobalHooks() + s:loadFiletypeHooks(&filetype)
    endif

    return b:wrapA_hooks
endfunction " }}}

function! wrapA#hooks#execute(name, ...) abort " {{{
    " Reverse the order of the hooks for post hooks so that a pre hook with a
    " low priority is executed before and a post hook is executed after
    " For instance for a hook responsible to preserve the cursor position it
    " must be the first to be executed to save the position of the cursor but
    " the last to be executed to restore it after all other hooks have been
    " executed
    let l:hooks = a:name =~? '\v^post' ? reverse(copy(s:load())) : s:load()

    for hook in l:hooks
        silent! call call(printf('%s#%s', hook, a:name), a:000)
    endfor
endfunction " }}}

" vim: ts=2 sw=2 et fdm=marker
