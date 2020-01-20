let g:vlime_loop_keywords = [
            \ 'with',
            \ 'initially',
            \ 'finally',
            \ 'do',
            \ 'doing',
            \ 'return',
            \ 'collect',
            \ 'collecting',
            \ 'append',
            \ 'appending',
            \ 'nconc',
            \ 'nconcing',
            \ 'count',
            \ 'counting',
            \ 'sum',
            \ 'summing',
            \ 'maximize',
            \ 'maximizing',
            \ 'minimize',
            \ 'minimizing',
            \ 'if',
            \ 'when',
            \ 'unless',
            \ 'else',
            \ 'end',
            \ 'while',
            \ 'until',
            \ 'repeat',
            \ 'always',
            \ 'never',
            \ 'thereis',
            \ 'for',
            \ 'as'
            \ ]

function! s:isEOL()
    return col('.') == col('$')-(mode() == 'n')
endfunction

function! s:isBOL()
    return col('.') == 1
endfunction

function! s:CursorChar()
    let line = getline('.')
    let col = col('.')
    let char = line[col-1]
    return char
endfunction

function! s:MoveNextChar()
    if s:isEOL()
        execute "normal j0"
    else
        execute "normal l"
    endif
endfunction

function! s:MovePrevChar()
    if s:isBOL()
        execute "normal k$"
    else
        execute "normal h"
    endif
endfunction

function! vlime#util#sexp#SkipSpaces(...)
    let flags = get(a:000, 0, '')
    call search('\S', flags . 'c')
endfunction

function! vlime#util#sexp#SkipComments(...)
    let flags = get(a:000, 0, '')
    let syntax = map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
    if index(syntax, 'lispComment') >= 0
        if flags =~ 'b'
            execute "normal k$"
        else
            execute "normal j0"
        endif
    elseif index(syntax, 'lispCommentRegion') >= 0
        if flags =~ 'b'
            call search('#|', flags . 'c')
            call s:MovePrevChar()
        else
            call search('|#', flags . 'ce')
            call s:MoveNextChar()
        endif
    endif
endfunction

function! vlime#util#sexp#ForwardSexp()
    call vlime#util#sexp#SkipComments('W')
    let char = s:CursorChar()
    if char == '('
        call searchpair('(', '', ')', 'W')
        call s:MoveNextChar()
    elseif char !~ '\s'
        call search('\s\|[()"]', 'W')
    endif
    while v:true
        let pos = getpos('.')
        call vlime#util#sexp#SkipSpaces('W')
        call vlime#util#sexp#SkipComments('W')
        if pos == getpos('.')
            break
        endif
    endwhile
endfunction

function! vlime#util#sexp#BackwardSexp()
    call vlime#util#sexp#SkipComments('bW')
    let char = s:CursorChar()
    if char == ')'
        call searchpair('(', '', ')', 'bW')
        call s:MovePrevChar()
    elseif char !~ '\s'
        call search('\s\|[()"]', 'bW')
    endif
    while v:true
        let pos = getpos('.')
        call vlime#util#sexp#SkipSpaces('bW')
        call vlime#util#sexp#SkipComments('bW')
        if pos == getpos('.')
            break
        endif
    endwhile
    let char = s:CursorChar()
    if char == ')'
        call searchpair('(', '', ')', 'bW')
    elseif char == '"'
        call searchpair('"', '', '"', 'bW')
    else
        call search('\s\|[()"]', 'bW')
        call s:MoveNextChar()
    endif
endfunction

function! vlime#util#sexp#CursorToken()
    let pos = getpos('.')
    call search('\s\|[("]\|^', 'cb')
    call vlime#util#sexp#SkipSpaces('W')
    call search('[^("]', 'c')
    let col = col('.')
    let end = searchpos('\s\|[)"]\|$', 'cnW')
    let token = getline('.')[col-1:end[1]-1]
    let token = substitute(token, '^\s*\(.\{-}\)\s*$', '\1', '')
    call setpos('.', pos)
    return token
endfunction

function! vlime#util#sexp#PreviousLoopClause(...)
    let endpos = get(a:000, 0, getpos('^'))
    while v:true
        while v:true
            call vlime#util#sexp#BackwardSexp()
            let char = s:CursorChar()
            if char != '('
                break
            endif
        endwhile
        let pos = getpos('.')
        if pos[1] < endpos[1] || (pos[1] == endpos[1] && pos[2] < endpos[2])
            let token = v:null
            break
        endif
        let token = vlime#util#sexp#CursorToken()
        if index(g:vlime_loop_keywords, token) >= 0
            break
        endif
    endwhile
    return token
endfunction
