" Test on Sample 3, go to 'function' and :norm vakd, repeat on 'endfunction'
" and inside the block.
call vimtest#StartTap()
call vimtap#Plan(5)
edit sample_003.vim
exec 'runtime ftplugin/vim/'.fname.'.vim'
call vimtap#Ok(mapcheck(maps.pva, 'v') != '', 'Check <Plug> mapping.')
call vimtap#Ok(maparg(maps.va, 'v') =~# maps.pva, 'Check Visual All mapping.')
2
normal 0vakd
call vimtap#Is(getline(1,line('$')), ['" Sample 3', ''], 'Check if the selection from "function" was correct.')
undo
9
normal 0vakd
call vimtap#Is(getline(1,line('$')), ['" Sample 3', ''], 'Check if the selection from "endfunction" was correct.')
undo
3
normal 0vakd
call vimtap#Is(getline(1,line('$')), ['" Sample 3', ''], 'Check if the selection from inside the block was correct.')
call vimtest#SaveOut()
call vimtest#Quit()
