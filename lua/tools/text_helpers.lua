local M = {}

vim.cmd([[
function! CopyMatches(reg)
  let hits = []
  %s//\=len(add(hits, submatch(0))) ? submatch(0) : ''/gne
  let reg = empty(a:reg) ? 'c' : a:reg
  execute 'let @'.reg.' = join(hits, "\n") . "\n"'
endfunction
command! -register Cm call CopyMatches(<q-reg>)

function! WrapSelection(left, right)
  let save_reg = @"
  " NOTE(jlima): '< jumps to the exact start line and column of the visual selection.
  normal! `<
  call search('\S', 'c')
  let start_pos = getpos('.')
  normal! `>
  let end_pos = getpos('.')

  call setpos('.', end_pos)
  execute "normal! a" . a:right
  call setpos('.', start_pos)
  execute "normal! i" . a:left
  let @" = save_reg
  startinsert
endfunction

xnoremap ' :<C-u>call WrapSelection("'", "'")<CR>
xnoremap ` :<C-u>call WrapSelection('`', '`')<CR>
xnoremap ( :<C-u>call WrapSelection('(', ')')<CR>
xnoremap [ :<C-u>call WrapSelection('[', ']')<CR>

function! DuplicateAndMark()
  let l:c = col('.')
  execute "normal! yyP"
  call cursor(line('.'), l:c)
  execute "normal! j"
  redraw
  echo "Mark set"
endfunction

inoremap <silent> <C-,> <C-o>:call DuplicateAndMark()<CR>
nnoremap <silent> <C-,> <cmd>call DuplicateAndMark()<CR>
]])

return M
