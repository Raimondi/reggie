" Test on Sample 1, go to the middle and :norm vakakakd
call vimtest#StartTap()
call vimtap#Plan(3)
edit sample_001.vim
exec 'runtime ftplugin/vim/'.fname.'.vim'
26
normal 0vakakakd
call vimtap#Ok(mapcheck(maps.pva, 'v') != '', 'Check <Plug> mapping.')
call vimtap#Ok(maparg(maps.va, 'v') =~# maps.pva, 'Check Visual All mapping.')
call vimtap#Is(getline(1,line('$')), ['" Sample 1', ''], 'Check if the selection was correct.')
call vimtest#SaveOut()
call vimtest#Quit()
