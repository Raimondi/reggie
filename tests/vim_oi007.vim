" Test on Sample 7, go to last line outside block and :norm dik
call vimtest#StartTap()
call vimtap#Plan(3)
edit sample_007.vim
exec 'runtime ftplugin/vim/'.fname.'.vim'
call vimtap#Ok(mapcheck(maps.poi, 'o') != '', 'Check <Plug> mapping.')
call vimtap#Ok(maparg(maps.oi, 'o') =~# maps.poi, 'Check Visual All mapping.')
$
normal 0dik
call vimtap#Is(getline(1,line('$')), ['" Sample 7', '', 'try', '  let i = 0', '  echom ''i: ''.i', 'catch', '  echoe 1', 'finally', '  echom i', 'endtry', ''], 'Check if the selection was correct.')
call vimtest#SaveOut()
call vimtest#Quit()
