" Test on Sample 2, go to 'if' and :norm vakd, repeat on 'endif' and inside
" the block.
call vimtest#StartTap()
call vimtap#Plan(5)
edit sample_002.vim
exec 'runtime ftplugin/vim/'.fname.'.vim'
call vimtap#Ok(mapcheck(maps.pva, 'v') != '', 'Check <Plug> mapping.')
call vimtap#Ok(maparg(maps.va, 'v') =~# maps.pva, 'Check Visual All mapping.')
4
normal 0vakd
call vimtap#Is(getline(1,4), ['" Sample 2', 'let i = 1', '', ''], 'Check if the selection from "if" was correct.')
undo
16
normal 0vakd
call vimtap#Is(getline(1,4), ['" Sample 2', 'let i = 1', '', ''], 'Check if the selection from "endif" was correct.')
undo
7
normal 0vakd
call vimtap#Is(getline(1,4), ['" Sample 2', 'let i = 1', '', ''], 'Check if the selection from "endif" was correct.')
call vimtest#SaveOut()
call vimtest#Quit()
