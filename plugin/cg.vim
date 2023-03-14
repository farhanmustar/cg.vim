command! -nargs=+ CG call cg#comp(<q-args>)
command! -nargs=+ CGC call cg#chat([<q-args>], 0, -1)
command! -nargs=+ CGCode call cg#chat([<q-args>], 1, -1)
