" Test on Sample 5, go to 'augroup' and :norm vikikd, repeat on 'augroup END'.
call vimtest#StartTap()
call vimtap#Plan(4)
edit sample_005.vim
exec 'runtime ftplugin/vim/'.fname.'.vim'
3
normal 0vikd
call vimtap#Ok(mapcheck(maps.pvi, 'v') != '', 'Check <Plug> mapping.')
call vimtap#Ok(maparg(maps.vi, 'v') =~# maps.pvi, 'Check Visual All mapping.')
call vimtap#Is(getline(1,line('$')), ['" Sample 5', '', 'augroup oops', 'augroup END'], 'Check if the selection from "augroup" was correct.')
undo
7
normal 0vikd
call vimtap#Is(getline(1,line('$')), ['" Sample 5', '', 'augroup oops', 'augroup END'], 'Check if the selection from "augroup END" was correct.')
call vimtest#SaveOut()
call vimtest#Quit()
