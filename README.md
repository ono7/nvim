## just some quick reminders

```
--- 🐇 Follow the white Rabbit...

http://vimcasts.org/categories/git/

find detected root dir

lua print(vim.lsp.get_clients({bufnr=0})[1].config.root_dir)

* view all compilers included with vim
:e $VIMRUNTIME/compiler
:compiler go
:make % or :make

* add all go files to arg list, :args **/*.go

* set dir to current open file, :cd %:h
* add all files to buff for faster navigation :argadd **/*.py
  * apply commands to open args list
    :sall
    :tab sall
    :argdo %s/test/Test/gc
* :write ++p (creates directories if they dont exists)

use /<c-r><c-w> will fill in the word under the cursor, same with ?<c-r><c-w>

:%bd (close all buffers)

* neovim 0.11 defaults for lsp_attach

"grn" is mapped in Normal mode to |vim.lsp.buf.rename()|
"gra" is mapped in Normal and Visual mode to |vim.lsp.buf.code_action()|
"grr" is mapped in Normal mode to |vim.lsp.buf.references()|
"gri" is mapped in Normal mode to |vim.lsp.buf.implementation()|
"grt" is mapped in Normal mode to |vim.lsp.buf.type_definition()|
"gO" is mapped in Normal mode to |vim.lsp.buf.document_symbol()|
CTRL-S is mapped in Insert mode to |vim.lsp.buf.signature_help()|

* :s/foo/<Ctrl-R>0/g | replace with contents of unnamed reg 0
* use :b <part of buffer name><tab> to find open tags

redirect vim command output to registers

:redir @" | messages | redir end
:redir @a | execute 'lua =vim.lsp.get_clients()[1].server_capabilities.codeActionProvider' | redir END
:let @" = system('python3 ' . expand('%') . '--test=20')

-- encode contents of a register and save them back to the register

:let @" = system('base64', @")
:let @* = execute("message")

better workflow:
--- stores the output to a variable that can be assigned to a register

:redir => m
:do something
:do something else
:redir end
:let @" = m

then in normal mode: ""p

excellent way to make changes without crashing out completely

local ok, _ = pcall(vim.cmd, 'colorscheme ayu')
if not ok then
  vim.cmd 'colorscheme default' -- if the above fails, then use default
  vim.notify("colorscheme ayu failed")
end

mv 1.{bak,py} (1.bak -> 1.py) move filenames in shell, requires file.(src,dest)

c-w + x -- swap splits in vim with next adjacent window

c-/  show/close quickfix list
c-q show diagnostic errors in quickfix list

<leader>nq - sets noqa for the particular diagnostics error

read hidden chars in files like BOM or hidden UTF8
enables binary mode
:e ++bin

reopen last active file in the tab
:tab sb #

:tab sball
```
