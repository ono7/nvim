" NOTE(jlima): Check buffer-local compiler state so new buffers can still load this compiler.
if exists("current_compiler")
  finish
endif
let current_compiler = "ansible"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

" NOTE(jlima): Run offline to skip Galaxy checks and discard stderr summary noise.
" CompilerSet makeprg=eval\ 'ansible-lint\ -f\ pep8\ --nocolor\ --show-relpath\ --offline\ %:S\ 2>/dev/null'

" NOTE(jlima): Omit eval wrapper; $* injects extra :make flags before target file and stderr redirect.
CompilerSet makeprg=ansible-lint\ -f\ pep8\ --nocolor\ --show-relpath\ --offline\ $*\ %:S\ 2>/dev/null

" NOTE(jlima): Explicitly parse pep8 file:line:col: message and file:line: message.
CompilerSet errorformat=%f:%l:%c:\ %m,%f:%l:\ %m,%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save
