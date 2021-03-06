" Test on Sample 4, go to 'while' and :norm dik, repeat on 'endwhile' and
" inside the block.
call vimtest#StartTap()
call vimtap#Plan(5)
edit sample_004.vim
exec 'runtime ftplugin/vim/'.fname.'.vim'
call vimtap#Ok(mapcheck(maps.poi, 'o') != '', 'Check <Plug> mapping.')
call vimtap#Ok(maparg(maps.oi, 'o') =~# maps.poi, 'Check Visual All mapping.')
3
normal 0dik
call vimtap#Is(getline(1,line('$')), ['" Sample 4', 'let i = 2', 'while i > 2', 'endwhile'], 'Check if the selection from "while" was correct.')
undo
13
normal 0dik
call vimtap#Is(getline(1,line('$')), ['" Sample 4', 'let i = 2', 'while i > 2', 'endwhile'], 'Check if the selection from "endwhile" was correct.')
undo
5
normal 0dik
call vimtap#Is(getline(1,line('$')), ['" Sample 4', 'let i = 2', 'while i > 2', 'endwhile'], 'Check if the selection from inside the block was correct.')
call vimtest#SaveOut()
call vimtest#Quit()
