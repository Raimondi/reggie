" File:        autoload/ktextobjects.vim
" Version:     0.1a
" Modified:    2011-00-00
" Description: This plugin provides new text objects for keyword based blocks.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      The new text objects are 'ik' and 'ak'. Place this file in
"              'autoload/' inside $HOME/.vim or somewhere else in your
"              runtimepath.
"
"              :let testing_KeywordTextObjects = 1 to allow reloading of the
"              plugin without closing Vim.
"
"              Multiple sentences on a single line are not handled by this
"              plugin, the text objects might not work or work in an
"              unexpected way.
"
" Pending:     - Consider continued lines for inner text objects.
"              - Use separate b:variables for each custom value.
"              - Allow matching on the same line.
" ============================================================================

" Load guard {{{1
if &cp
  finish
endif
let save_cpo = &cpo
set cpo&vim

if !exists('loaded_KeywordTextObjects') || exists('testing_KeywordTextObjects')
  echom '----Loaded on: '.strftime("%Y %b %d %X")

  function! Test(first, last, test,...)
    if a:test == 1
      return s:Match(a:first, b:ktextobjects_dict.start).', '.s:Match(a:first, b:ktextobjects_dict.middle).', '.s:Match(a:first, b:ktextobjects_dict.end)
    elseif a:test == 2
      return s:FindTextObject([a:first,0], [a:last,0], b:ktextobjects_dict.middle)
    elseif a:test == 3
      return searchpairpos(b:ktextobjects_dict.start, b:ktextobjects_dict.middle, b:ktextobjects_dict.end, a:1, b:ktextobjects_dict.skip)
    elseif a:test == 4
      return match(getline('.'), 'bWn')
    elseif a:test == 5
      return searchpos(b:ktextobjects_dict.start,'bn')
    else
      throw 'Ooops!'
    endif
  endfunction
  command! -bar -range -buffer -nargs=+ Test echom string(Test(<line1>, <line2>, <f-args>))
else
  finish
endif
let loaded_KeywordTextObjects = '0.1a' "}}}1

" Variables {{{1
" One Dict to rule them all, One Dict to find them,
" One Dict to bring them all and in the darkness unlet them...
let s:vars = {}

" VimL settings: {{{2
let s:vars.vim =
      \ {'skip'     : '',
      \  'start'    : '',
      \  'middle'   : '',
      \  'end'      : '',
      \  'allmap'   : 'ak',
      \  'innermap' : 'ik'}
" Lines where this expression returns 1 will be skipped
" Expression borrowed from default vim ftplugin
let s:vars.vim.skip =
      \ 'getline(".") =~ "^\\s*sy\\%[ntax]\\s\\+region" ||' .
      \ 'synIDattr(synID(line("."),col("."),1),"name") =~? '.
      \ '"comment\\|string\\|vim\k\{-}var"'

" List of words that start a block at the beginning of the line
let s:vars.vim.beg_words =
      \ '<fu%[nction]>|<%(wh%[ile]|for)>|<if>|<try>|'.
      \ '<aug%[roup]\s+%(END>)@!\S'

" Start of the block matches this
let s:vars.vim.start = '\C\v^\s*\zs%('.s:vars.vim.beg_words.')'

" Middle of the block matches this
let s:vars.vim.middle= '\C\v^\s*\zs%(<el%[seif]>|<cat%[ch]>|<fina%[lly]>)'

" End of the block matches this
let s:vars.vim.end   =
      \ '\C\v^\s*\zs%(<endf%[unction]>|<end%(w%[hile]|fo%[r])>|'.
      \ '<en%[dif]>|<endt%[ry]>|<aug%[roup]\s+END>)'

" Ruby settings: {{{2
let s:vars.ruby =
      \ {'skip'     : '',
      \  'start'    : '',
      \  'middle'   : '',
      \  'end'      : '',
      \  'allmap'   : 'ak',
      \  'innermap' : 'ik'}
" Lines where this expression returns 1 will be skipped
" Expression borrowed from default ruby ftplugin
let s:vars.ruby.skip =
      \ "synIDattr(synID(line('.'),col('.'),0),'name') =~ '"            .
      \ "\\<ruby\\%(String\\|StringDelimiter\\|ASCIICode\\|Escape\\|"   .
      \ "Interpolation\\|NoInterpolation\\|Comment\\|Documentation\\|"  .
      \ "ConditionalModifier\\|RepeatModifier\\|OptionalDo\\|"          .
      \ "Function\\|BlockArgument\\|KeywordAsMethod\\|ClassVariable\\|" .
      \ "InstanceVariable\\|GlobalVariable\\|Symbol\\)\\>'"

" List of words that start a block at the beginning of the line
let s:vars.ruby.beg_words =
      \ '<def>|<module>|<class>|<case>|<if>|<unless>|<begin>|'.
      \ '<for>|<until>|<while>|<catch>'

" Start of the block matches this
let s:vars.ruby.start =
      \ '\C\v^\s*\zs%('.s:vars.ruby.beg_words.')|'.
      \ '%(%('.s:vars.ruby.beg_words.').*)@<!<do>'

" Middle of the block matches this
let s:vars.ruby.middle= '\C\v^\s*\zs%(<els%(e|if)>|<rescue>|<ensure>|<when>)'

" End of the block matches this
let s:vars.ruby.end   = '\C\v^\s*\zs<end>'

" }}}1

" Functions {{{1
function! s:get_dict(filetype) " {{{2
  if exists('b:ktextobjects_start') && exists('b:ktextobjects_end')
    let default = get(s:vars, a:filetype, {'skip': '0', 'middle': '', 'allmap': 'k', 'innermap': 'k'})
    return {
          \ 'skip'     : get(b:, 'b:ktextobjects_skip', default.skip),
          \ 'start'    : b:ktextobjects_start,
          \ 'middle'   : get(b:, 'b:ktextobjects_middle', default.middle),
          \ 'end'      : b:ktextobjects_end,
          \ 'allmap'   : 'a'.get(b:, 'b:ktextobjects_map', default.allmap),
          \ 'innermap' : 'i'.get(b:, 'b:ktextobjects_map', default.innermap)}
  else
    return get(s:vars, a:filetype, {})
  endif
endfunction "}}}2

function! ktextobjects#init(...) "{{{2
  call s:info('INIT', 'Start: '.string(a:000))
  if a:0
    let filetype = a:1
  else
    let filetype = &filetype
  endif
  " Get dictionary
  let b:ktextobjects_dict = s:get_dict(filetype)
  if b:ktextobjects_dict == {}
    " Filetype not supported, erase any trace of our presence
    unlet b:ktextobjects_dict
    return
  endif
  call s:dbg('INIT', string(b:ktextobjects_dict))

  " Set b:undo_ftplugin {{{3
  let s:undo_ftplugin =
        \ 'sil! ounmap <buffer> '                               .
        \ b:ktextobjects_dict.allmap.'|'                        .
        \ 'sil! ounmap <buffer> '                               .
        \ b:ktextobjects_dict.innermap.'|'                      .
        \ 'sil! vunmap <buffer> '                               .
        \ b:ktextobjects_dict.allmap.'|'                        .
        \ 'sil! vunmap <buffer> '                               .
        \ b:ktextobjects_dict.innermap.'|'                      .
        \ 'sil! ounmap <buffer> <Plug>KeywordTextObjectsAll|'   .
        \ 'sil! ounmap <buffer> <Plug>KeywordTextObjectsInner|' .
        \ 'sil! vunmap <buffer> <Plug>KeywordTextObjectsAll|'   .
        \ 'sil! vunmap <buffer> <Plug>KeywordTextObjectsInner|' .
        \ 'sil! unlet b:ktextobjects_dict'
  if exists('b:undo_ftplugin') && b:undo_ftplugin !~ 'unlet b:ktextobjects'
    if b:undo_ftplugin =~ '^\s*$'
      let b:undo_ftplugin = s:undo_ftplugin
    else
      let b:undo_ftplugin = s:undo_ftplugin.'|'.b:undo_ftplugin
    endif
  elseif !exists('b:undo_ftplugin')
    let b:undo_ftplugin = s:undo_ftplugin
  endif

  " Mappings: {{{3
  for map in [b:ktextobjects_dict.allmap, b:ktextobjects_dict.innermap]
    " Create <Plug>mappings
    "exec 'onoremap <silent> <buffer> '.
    "      \ '<Plug>KeywordTextObjects'.
    "      \ (map == b:ktextobjects_dict.allmap ? 'All' : 'Inner').' '.
    "      \ ':<C-U>call <SID>TextObjects'.
    "      \ (map == b:ktextobjects_dict.allmap ? 'All' : 'Inner').
    "      \ '(0)<CR>'
    exec 'onoremap <silent> <buffer> <expr>'.
          \ '<Plug>KeywordTextObjects'.
          \ (map == b:ktextobjects_dict.allmap ? 'All' : 'Inner').' '.
          \ '<SID>TextObjects'.
          \ (map == b:ktextobjects_dict.allmap ? 'All' : 'Inner').'(0)'

    exec 'vnoremap <silent> <buffer> '.
          \ '<Plug>KeywordTextObjects'.
          \ (map == b:ktextobjects_dict.allmap ? 'All' : 'Inner').' '.
          \ ':call <SID>TextObjects'.
          \ (map == b:ktextobjects_dict.allmap ? 'All' : 'Inner').'(1)<CR><Esc>gv'
    for mode in ['o', 'v']
    " Create useful mappings
      if !exists('g:testing_KeywordTextObjects')
        " Be nice with existing mappings
        if !hasmapto('<Plug>KeywordTextObjects_'.map, mode)
          exec mode.'map <unique> <buffer> '.map.' <Plug>KeywordTextObjects'.
                \ (map == b:ktextobjects_dict.allmap ? 'All' : 'Inner')
        endif
      else
        exec 'silent! '.mode.'unmap <buffer> '.map
        exec mode.'map <buffer> '.map.' <Plug>KeywordTextObjects'.
              \ (map == b:ktextobjects_dict.allmap ? 'All' : 'Inner')
      endif
    endfor
  endfor
endfunction "}}}2

function! s:TextObjectsAll(visual,...) range "{{{2
  call s:info('TOA', 'Start: '.a:visual.','.string(a:000))
  " Recursing?
  if a:0
    let firstline = a:1
    let lastline  = a:2
    let count1    = a:3 - 1
  else
    let firstline = a:firstline
    let lastline  = a:lastline
    let count1    = v:count1
    "let count1    = v:count1 < 1 ? 1 : v:count1
  endif
  call s:dbg('TOA', 'count1: '.count1.', firstline: '.firstline.', lastline: '.lastline)
  let start         = [0,0]
  let end           = [-1,0]
  let middle_p      = ''

  let t_start = [firstline + 1, 0]
  let t_end   = [lastline - 1, 0]

  call s:deepdbg('TOA', 'Initial t_start;t_end: '.string(t_start).';'.string(t_end))
  let match_both_outer = (
        \ s:Match(t_start[0] - 1, b:ktextobjects_dict.start) &&
        \ s:Match(t_end[0] + 1, b:ktextobjects_dict.end))
  for passes in [1,2]

    " Let's get some luv
    let [t_start, t_end] = s:FindTextObject([t_start[0] - 1, 0], [t_end[0] + 1, 0], middle_p)

    call s:dbg('TOA', string(t_start).';'.string(t_end).':'.passes)
    if t_start[0] > 0 && t_end[0] > 0
      let start = t_start
      let end   = t_end
      call s:dbg('TOA', 'start;end: '.string(start).';'.string(end).', passes: '.passes)
    else
      break
    endif

    " Repeat only if necessary
    if !(match_both_outer && passes == 1 &&
          \ start[0] == firstline && end[0] == lastline)
      break
    endif
  endfor

  if count1 > 1
    let [start, end] = s:TextObjectsAll(a:visual, start[0], end[0], count1)
  endif

  if a:0
    return [start, end]
  endif

  call s:dbg('TOA', 'start;end: '.string(start).';'.string(end).', passes: '.passes)
  if a:visual
    if end[0] >= start[0] && start[0] >= 1 && end[0] >= 1
      " Do visual magic
      exec "normal! \<Esc>"
      call cursor(start)
      exec "normal! v".end[0]."G$h"
      call s:dbg('TOA', 'start;end: '.string(start).';'.string(end).', passes: '.passes)
    endif
  else
    if end[0] >= start[0] && start[0] >= 1 && end[0] >= 1
      " Do operator pending magic
      call s:dbg('TOA', getline(start[0])[:start[1] - 2])
      if start[1] <= 1 || getline(start[0])[:start[1] - 2] =~ '^\s*$'
        " Delete whole lines
        let to_eol   = v:operator =~? '^gu$' ? '$h' : '$'
        let from_bol = '0'
      else
        " Don't delete text behind start of block and leave one <CR>
        let to_eol   = '$h'
        let from_bol = ''
      endif
      return ':call cursor('.string(start).')|exec "normal! '.from_bol.'v'.end[0]."G".to_eol."\"\<CR>:silent! call repeat#set(v:operator.b:ktextobjects_dict.allmap, ".count1.")\<CR>"

    else
      " No pair found, do nothing
      return "\<Esc>"
    endif
  endif

endfunction " }}}2

function! s:TextObjectsInner(visual, ...) range "{{{2
  call s:info('TOI', 'Start: '.a:visual.','.(a:0 ? ','.join(a:000, ',') : '').')')

  " Recursing?
  if a:0 " {{{
    let firstline = a:1[0]
    let lastline  = a:2[0]
    let count1    = a:3 - 1
    let original  = [[firstline, 1], [lastline, len(getline(lastline)) + 1]]
  else
    let firstline = a:firstline
    let lastline  = a:lastline
    let count1    = v:count1 < 1 ? 1 : v:count1
    let original  = [getpos("'<")[1:2], getpos("'>")[1:2]]
  endif " }}}
  let current     = {'start': [firstline,0], 'end': [lastline,0]}
  let middle_p    = b:ktextobjects_dict.middle
  let line_eof    = line('$')
  let l:count     = 0
  let d_start     = 0
  let d_end       = 0
  let i           = 0
  call s:dbg("TOI", "count1: ".count1.', v:count1: '.v:count1.', v:count: '.v:count)

  while i <= 2 && (current.start[0] + d_start) > 0 && (current.end[0] + d_end) <= line_eof
    let i += 1
    " Get a text object
    let [current.start, current.end] = s:FindTextObject(
          \ [current.start[0] + d_start, 0], [current.end[0] + d_end, 0], middle_p)
    call s:dbg('TOI', 'Inner loop Current: '.string(current).', count: '.i)

    " If it's null, stop looking
    if [current.start, current.end] == [[0,0],[0,0]]
      break
    endif
    if a:0 && i == 2
      break
    endif
    " Repeat? {{{
    let is_repeat = s:is_repeat(firstline, lastline, current.start[0], current.end[0], a:visual, a:0, original)

    if is_repeat == 4 || is_repeat == -2
      " It is repeated with an inner middle block
      let middle_p = ''
      let d_start  = 0
      let d_end    = 0
    elseif is_repeat == 3
      " It is repeated with an inner middle block and a whole block
      let middle_p = ''
      let d_start  = -1
      let d_end    = 1
    elseif is_repeat == 2 || is_repeat == -1
      " The text object limits are just over and under the original
      " selection
      " It is repeated, with an inner block
      let middle_p    = b:ktextobjects_dict.middle
      let d_start  = -1
      let d_end    = 1
    elseif is_repeat == 1
      " It is repeated, with a whole block
      let middle_p    = b:ktextobjects_dict.middle
      let d_start  = -1
      let d_end    = 1
    else
      " No need to loop
      break
    endif "}}}
  endwhile

  if count1 > 1 && [current.start,current.end] != [[0,0],[0,0]] "{{{
    " Let's recurse
    let [current.start,current.end] = s:TextObjectsInner(a:visual, [current.start[0], 1], [current.end[0], 1], count1)
  endif

  call s:dbg('TOI', 'Last Current: '.string(current).', count1: '.count1)
  if a:0
    return [current.start,current.end]
  endif
  if a:visual
    if current.end[0] >= current.start[0] && current.start[0] >= 1 && current.end[0] >= 1 && current.end[0] - current.start[0] > 1
      " Do visual magic
      exec "normal! \<Esc>".(current.start[0] + 1).'G'
      exec "normal! 0v".(current.end[0] - 1)."G$"
    endif
  else
    if current.end[0] >= current.start[0] && current.start[0] >= 1 && current.end[0] >= 1 && current.end[0] - current.start[0] > 1
      if v:operator =~? '^gu$'
        let to_end = '$h'
      else
        let to_end = '$'
      endif
      " Do operator pending magic
      "exec 'normal! '.(current.start[0] + 1)
      "      \ .'G0'.v:operator.':normal! v'.(current.end[0] - 1)."G".to_end."\<CR>"
      "silent! call repeat#set(v:operator.b:ktextobjects_dict.innermap)
      return ':exec "normal! '.(current.start[0] + 1).
            \ 'G0v'.(current.end[0] - 1)."G".to_end."\"\<CR>".
            \ ":silent! call repeat#set(v:operator.b:ktextobjects_dict.innermap, ".
            \ count1.")\<CR>"

    else
      " No pair found, do nothing
      return "\<Esc>"
    endif
  endif "}}}
endfunction "}}}2

function! s:is_repeat(firstl, lastl, cfirstl, clastl, visual, recursive, original) "{{{2
  call s:info('IR', "is_repeat(".string(a:firstl).','.string(a:lastl).','.string(a:cfirstl).','.string(a:clastl).','.string(a:visual).','.string(a:recursive).','.string(a:original).')')
  let is_block = 0
  if [a:firstl, a:lastl] == [a:cfirstl, a:clastl] || a:recursive
    " The original selection's range is the same as the one from the text
    " object.
    " It is a whole block
    let is_block = 1
  endif
  let is_repeat = 0
  " If:
  " - It's recursive OR
  " - It's visual AND
  "   - The selection is a previously selected text block
  if a:recursive
    " Determine what is selected {{{
    if b:ktextobjects_dict.middle != '' &&
          \(getline(a:firstl) =~ b:ktextobjects_dict.middle ||
          \ getline(a:lastl) =~ b:ktextobjects_dict.middle)
      " The line over and/or under matches a b:ktextobjects_dict.middle
      let is_repeat = -2
    else
      " It is repeated, with a whole inner block
      let is_repeat = -1
    endif "}}}
  elseif a:visual
        \ && (a:original[0][1] == 1
        \ && a:original[1][1] >= len(getline(getpos("'>")[1])) + 1)

    " Determine what is selected "{{{
    if b:ktextobjects_dict.middle != '' &&
          \ (getline(a:firstl - 1) =~ b:ktextobjects_dict.middle ||
          \ getline(a:lastl + 1) =~ b:ktextobjects_dict.middle)
      " The line over and/or under matches a b:ktextobjects_dict.middle
      if !is_block
        " It is repeated with an inner middle block
        let is_repeat = 4
      else
        " It is repeated with an inner middle block and a whole block
        let is_repeat = 3
      endif
    elseif [a:firstl - 1, a:lastl + 1] == [a:cfirstl, a:clastl]
      " The text object limits are just over and under the original
      " selection
      " It is repeated, with an inner block
      let is_repeat = 2
    elseif is_block
      " It is repeated, with a whole block
      let is_repeat = 1
    endif "}}}
  endif
  call s:dbg('IR', 'is_repeat: '.is_repeat.', is_block: '.is_block)
  return is_repeat
endfunction "}}}2

function! s:FindTextObject(first, last, middle, ...) "{{{2
  call s:info('FTO', 'Start: '.string(a:first).','.string(a:last).','.string(a:middle).join(a:000))

  " Default flags
  let flags = 'Wn'

  if a:0
    let l:count = a:1 + 1
  else
    let l:count = 1
  endif
  call s:dbg('FTO', 'count: '.l:count)
  if a:first[0] > a:last[0]
    throw 'Muy mal... a:first ('.string(a:first).') > a:last ('.string(a:last).')'
  endif
  call s:dbg('FTO', 'Range : '.string([a:first, a:last]))

  let first = {'start':[0,0], 'end':[0,0], 'range':0}
  let last  = {'start':[0,0], 'end':[0,0], 'range':0}

  " searchpair() starts looking at the cursor position. Find out where that
  " should be. Also determine if the current line should be searched.
  if s:Match(a:first[0], b:ktextobjects_dict.end)
    let spos   = 1
    let sflags = flags.'b'
  else
    let spos   = 9999
    let sflags = flags.'bc'
  endif

  " Let's see where they are
  call cursor(a:first[0], spos)
  let first.start  = searchpairpos(b:ktextobjects_dict.start,a:middle,b:ktextobjects_dict.end,sflags,b:ktextobjects_dict.skip)

  if a:middle == ''
    let s_match = s:Match(a:first[0], b:ktextobjects_dict.start)
  else
    let s_match = s:Match(a:first[0], b:ktextobjects_dict.start) || s:Match(a:first[0], a:middle)
  endif
  if s_match
    let epos   = 9999
    let eflags = flags
  else
    let epos   = 1
    let eflags = flags.'c'
  endif

  " Let's see where they are
  call cursor(a:first[0], epos)
  let first.end    = searchpairpos(b:ktextobjects_dict.start,a:middle,b:ktextobjects_dict.end,eflags,b:ktextobjects_dict.skip)

  call s:dbg('FTO', 'First : '.string([first.start, first.end]))
  if a:first == a:last "{{{
    let result = [first.start, first.end]
  else
    let [last.start, last.end] = s:FindTextObject(a:last, a:last, a:middle, l:count)
    call s:dbg('FTO', 'Last  : '.string([last.start, last.end]))

    let first.range  = first.end[0] - first.start[0]
    let last.range   = last.end[0] - last.start[0]
    if first.end[0] <= last.start[0] &&
          \ (getline(first.end[0])  =~ b:ktextobjects_dict.middle &&
          \   first.range > 0) &&
          \ (getline(last.start[0]) =~ b:ktextobjects_dict.middle &&
          \   last.range  > 0)
      " Looks like a middle inner match, start over without looking for
      " b:ktextobjects_dict.middle
      let result = s:FindTextObject(a:first, a:last, '', 1)
    else
      " Now, decide what to return
      if first.range > last.range
        if first.start[0] <= last.start[0] && first.end[0] >= last.end[0]
          " last is inside first
          let result = [first.start, first.end]
        elseif last.range == 0
          " Last is null
          let result = [first.start, first.end]
        else
          " Something is wrong, last is not inside first
          let result = [[0,0],[0,0]]
        endif
      elseif first.range < last.range
        if first.start[0] >= last.start[0] && first.end[0] <= last.end[0]
          " first is inside last
          let result = [last.start, last.end]
        elseif first.range == 0
          " first is null
          let result = [last.start, last.end]
        else
          " Something is wrong, first is not inside last
          let result = [[0,0],[0,0]]
        endif
      else
        if first.start[0] == last.start[0]
          " first and last are the same
          let result = [first.start, first.end]
        else
          " first and last are not the same
          "let result = [a:first, a:last]
          let result = [[0,0],[0,0]]
        endif
      endif
    endif
  endif "}}}
  call s:dbg('FTO', 'Result: '.string(result))
  "      \ . ', first: ' . string(first) . ', last' .
  "      \ string(last). ', spos: ' . spos . ', sflags: ' . sflags . ', epos: ' . epos . ', eflags: ' . eflags. '. middle_p: '.a:middle
  return result
endfunction "}}}2

function! s:Match(line, part) " {{{2
  call cursor(a:line, 1)
  let result = search(a:part, 'cW', a:line) > 0 && !eval(b:ktextobjects_dict.skip)
  call s:dbg('MA', result)
  return result
endfunction " }}}2

" Messages: {{{
let s:verbose_quiet = 0
let s:verbose_info  = 1
let s:verbose_debug = 2
let s:verbose_deep  = 3
function! s:log(level, msg, scope) "{{{
  if exists('g:ktextobjects_verbosity')
    let s:verbosity = g:ktextobjects_verbosity
  else
    let s:default_verbosity = s:verbose_quiet
    let s:verbosity = s:default_verbosity
  endif

  if exists('g:testing_KeywordTextObjects') && type(g:testing_KeywordTextObjects) == type([]) && len(g:testing_KeywordTextObjects) > 0
    let scope = index(g:testing_KeywordTextObjects, a:scope) >= 0
  else
    let scope = 1
  endif

  if a:level <= s:verbosity && scope
    echomsg a:msg
  endif
endfunction "}}}

function! s:info(scope, msg)
  call s:log(s:verbose_info, 'info: ' . a:scope . ' - '. a:msg, a:scope)
endfunction

function! s:dbg(scope, msg)
  call s:log(s:verbose_debug, 'dbg : ' . a:scope . ' - '. a:msg, a:scope)
endfunction

function! s:deepdbg(scope, msg)
  call s:log(s:verbose_deep, 'deep: ' . a:scope . ' - '. a:msg, a:scope)
endfunction
"}}}
let &cpo = save_cpo
" vim: set et sw=2 sts=2 tw=78: {{{1
