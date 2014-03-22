if exists('g:loaded_bufnewfile_template')
    finish
endif
let g:loaded_bufnewfile_template = 1

let s:bufnewfile_template_pl = expand('<sfile>:p:h')
    \ . '/../tools/bufnewfile-template.pl'

if !executable(s:bufnewfile_template_pl)
    finish
endif

exec 'autocmd BufNewFile *.* :%:!' . s:bufnewfile_template_pl . " '%'"
