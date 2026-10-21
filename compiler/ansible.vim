" NOTE(jlima): Prevent duplicate loading if compiler is already active in buffer.
if exists("current_compiler")
  finish
endif
let current_compiler = "ansible_lint"

" NOTE(jlima): Fallback for older Vim patch levels lacking :CompilerSet.
if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

" NOTE(jlima): Force pep8 output and strip ANSI codes for deterministic parsing.
" -q suppresses summary statistics that would otherwise pollute the quickfix list.
CompilerSet makeprg=ansible-lint\ -f\ pep8\ --nocolor\ -q\ %:S

" NOTE(jlima): Parse standard pep8 format (filename:lnum:col: code: message)
" and fallback to column-less matches if a rule only reports line numbers.
CompilerSet errorformat=%f:%l:%c:\ %m,%f:%l:\ %m,%-G%.%#
