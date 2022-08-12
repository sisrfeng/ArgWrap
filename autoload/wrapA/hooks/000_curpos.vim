fun! s:extractCursorPositionForUnwrappedArgs(range, args) abort
    let l:cursorColumn = col('.')
    let l:lineText = getline(a:range.lineStart)
    let l:position = {}

    let l:argNumber = 0
    for arg in a:args
        let l:argNumber += 1
        let l:argStart = stridx(l:lineText, arg)
        let l:argEnd = l:argStart + len(arg)

        if l:cursorColumn <= l:argStart
            let l:cursorColumn = l:argStart + 1
        en

        if l:argEnd < l:cursorColumn
            if l:lineText[l:cursorColumn - 1:] =~ '\v^,' " Cursor on the separator
                if !wrapA#getCfg('comma_first')
                    let l:cursorColumn = l:argEnd + 1
                el
                    let l:position.argNumber = l:argNumber + 1
                    let l:position.column = -1

                    break
                en
            elseif l:lineText[l:cursorColumn - 1:] =~ '\v^\s+,' " Cursor before the separator
                let l:cursorColumn = l:argEnd
            en
        en

        if l:cursorColumn <= l:argEnd + 1
            let l:position.argNumber = l:argNumber
            let l:position.column = l:cursorColumn - l:argStart

            break
        end
    endfor

    " If the position was not found it's because the cursor is after the last
    " arg
    if empty(l:position)
    let l:position.argNumber = l:argNumber
        let l:position.column = l:argEnd - l:argStart
    en

    return l:position
endf

fun! s:extractCursorPositionForWrappedArgs(range, args) abort " {{{
    let l:position = {}
    let l:isCommaFirst = wrapA#getCfg('comma_first')
    let l:cursorColumn = col('.')
    let l:cursorArgumentNumber = line('.') - a:range.lineStart
    " In case the cursor is on the start line
    let l:cursorArgumentNumber = min([len(a:args), l:cursorArgumentNumber])
    " In case the cursor is on the end line
    let l:cursorArgumentNumber = max([1, l:cursorArgumentNumber])
    let l:argLine = getline('.')
    let l:argText = a:args[l:cursorArgumentNumber - 1]
    let l:argStart = stridx(l:argLine, l:argText)
    let l:argEnd = l:argStart + len(l:argText)
    let l:position.argNumber = l:cursorArgumentNumber
    let l:position.column = l:cursorColumn - l:argStart

    if l:cursorColumn <= l:argStart
        let l:position.column = 1

        if l:isCommaFirst
            if l:argLine[l:cursorColumn - 1:] =~ '\v^,' " Cursor on the separator
                " The cursor should be placed on the separtor
                let l:position.argNumber -= 1
                let l:position.column = len(a:args[l:position.argNumber - 1]) + 1
            elseif l:argLine[l:cursorColumn - 1:] =~ '\v^\s+,' " Cursor before the separator
                " The cursor should be placed on the end of the previous arg
                let l:position.argNumber -= 1
                let l:position.column = len(a:args[l:position.argNumber - 1])
            en
        en
    en

    if l:argEnd < l:cursorColumn
        let l:position.column = len(l:argText)

        if !l:isCommaFirst
            if l:argLine[l:cursorColumn - 1:] =~ '\v^\s+,' " Cursor before the separator
                " The cursor should be placed on the end of the current arg
            elseif l:argLine[l:cursorColumn - 1:] =~ '\v^,' " Cursor on the separator
                " The cursor should be placed on the separator
                let l:position.column += 1
            en
        en
    en

    return l:position
endf " }}}

fun! s:getCursorPositionForWrappedArgs(range, container, args) abort " {{{
    let l:line = a:range.lineStart + a:container.cursor.argNumber
    let l:argStart = stridx(getline(l:line), a:args[a:container.cursor.argNumber - 1])
    let l:column = l:argStart + a:container.cursor.column

    return {'line': l:line, 'column': l:column}
endf " }}}

fun! s:getCursorPositionForUnwrappedArgs(range, container, args) abort " {{{
    let l:line = a:range.lineStart
    let l:column = a:range.colStart

    " For each args before the one where the cursor must be positioned
    for index in range(a:container.cursor.argNumber - 1)
        " Add the length of the arg + 2 for the separator ', '
        let l:column += len(a:args[index]) + 2
    endfor

    let l:column += a:container.cursor.column

    return {'line': l:line, 'column': l:column}
endf " }}}

fun! s:setCursorPosition(position) abort " {{{
    let l:curpos = getcurpos()
    let l:curpos[1] = a:position.line
    let l:curpos[2] = a:position.column

    call setpos('.', l:curpos)
endf  " }}}



"\ hooks
    fun! wrapA#hooks#000_curpos#pre_wrap(range, container, args) abort " {{{
        let a:container.cursor = s:extractCursorPositionForUnwrappedArgs(a:range, a:args)
    endf  " }}}

    fun! wrapA#hooks#000_curpos#pre_unwrap(range, container, args) abort " {{{
        let a:container.cursor = s:extractCursorPositionForWrappedArgs(a:range, a:args)
    endf  " }}}

    fun! wrapA#hooks#000_curpos#post_wrap(range, container, args) abort " {{{
        let l:position = s:getCursorPositionForWrappedArgs(a:range, a:container, a:args)

        call s:setCursorPosition(l:position)
    endf  " }}}

    fun! wrapA#hooks#000_curpos#post_unwrap(range, container, args) abort " {{{
        let l:position = s:getCursorPositionForUnwrappedArgs(a:range, a:container, a:args)

        call s:setCursorPosition(l:position)
    endf

