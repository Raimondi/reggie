" Regular Expression text-objects {{{1
" Define criteria dict abort {{{2
let c = {}
let c.kind = 'Regular Expression'
let c.objects = textobj#position_objects#new()
let c.tools = textobj#mapping_tools#new([c])
" c.get_positions(options) dict abort "{{{3
" Ditto
function! c.get_positions(options) dict
  call self.reset(a:options)
  let to = self.get_text_object(a:options)
  let area = self.post_process_text_object(to, a:options)
  "echom 'c.gp: area => ' . area.to_s()
  return [area.start().to_gpos(), area.end().to_gpos()]
endfunction "c.get_positions

" c.post_process_text_object(to, options) dict abort "{{{3
" Ditto
function! c.post_process_text_object(to, options) dict abort
  let type = self.tools.systems[a:options.id].post_processor_arg_type
   if type == 'o'
     let arg = a:to
   elseif type == 'l'
     let arg = a:to.to_l()
   elseif type == 'd'
     let arg = a:to.to_d()
   elseif type == 'm'
     let arg = a:to.to_dl()
   else
     echoe 'Post-Process Text Object: This should never be seen, ever!'
   endif
   let [pos1, pos2] = self.tools.systems[a:options.id].post_process(arg, a:options)
   return self.objects.new('area', self.objects.new('position', pos1), self.objects.new('position', pos2))
endfunction "c.post_process_text_object

" c.reset(options) dict abort "{{{3
" Ditto
function! c.reset(options) dict
  let self.skip = a:options.skip
  let self.patterns = a:options.patterns
endfunction "c.reset

" c.get_text_object(options) dict abort "{{{3
" Ditto
function! c.get_text_object(options) dict
  let pos1 = self.objects.new('position')
  if a:options.visual
    let pos2 = self.objects.new('position')
    call pos1.position(getpos("'<"))
    call pos2.position(getpos("'>"))
    let to = self.get_text_object_from_area(pos1, pos2, a:options)
  else
    call pos1.position(getpos('.'))
    let to = self.find_text_object(pos1, a:options)
  endif
  "echom 'gto: to => ' . to.to_s()
  if !to.valid()
    return to
  endif
  let original = self.objects.new('area')
  call original.start(pos1)
  call original.end(a:options.visual ? pos2 : pos1)
  if a:options.visual
    let final = self.post_process_text_object(to, a:options)
    if !final.valid()
      return self.objects.new('text_object')
    endif
    if original.contains(final)
      let to = self.expand_text_object(to, a:options)
      if !to.valid()
        return to
      endif
    endif
  endif
  "echo 'gto: count => ' . a:options.count
  for i in range(a:options.count - 1)
    let to_temp = self.expand_text_object(to, a:options)
    "echo 'gto: to_temp => ' . to_temp.to_s()
    if !to_temp.valid()
      break
    endif
    let to = to_temp
  endfor
  "echom 'gto: to => ' . to.to_s()
  return to
endfunction "c.get_text_object

" c.get_text_object_from_area(pos1, pos2, options) dict abort "{{{3
" Ditto
function! c.get_text_object_from_area(pos1, pos2, options) dict
  if a:pos1.equal(a:pos2)
    return self.find_text_object(a:pos1, a:options)
  endif
  let to1 = self.find_text_object(a:pos1, a:options)
  "echom 'c.gtofa: to1 => ' . to1.to_s()
  let to2 = self.find_text_object(a:pos2, a:options)
  "echom 'c.gtofa: to2 => ' . to2.to_s()
  let to = self.choose_text_object(to1, to2)
  if !to.valid() && to1.valid() && to2.valid() &&
        \ self.boundary_kind(to1.end()) == 'middle' &&
        \ self.boundary_kind(to2.start()) == 'middle'
    let to_all = self.find_text_object(a:pos1, {'inner': 0})
    if to_all.contains(to1) && to_all.contains(to2)
      let to = to1
      call to.end(to2.end())
    else
      return self.objects.new('text-object')
    endif
  endif
  if !to.valid()
    return self.objects.new('text-object')
  endif
  return to
endfunction "c.get_text_object_from_area

" c.find_text_object(pos, options) dict abort "{{{3
" Ditto
function! c.find_text_object(pos, options) dict
  let to = self.objects.new('text_object')
  let boundary = self.get_boundary(a:pos)
  let pos = self.objects.new('position')
  if self.boundary_kind(boundary) == 'start'
    "echom 'c.fto: '.1
    call to.start(boundary)
    call pos.position(self.find_from(a:pos, 1, a:options.inner))
    call to.end(self.get_boundary(pos))
  elseif self.boundary_kind(boundary) == 'middle' && a:options.inner
    "echom 'c.fto: '.2
    call to.start(boundary)
    call pos.position(self.find_from(a:pos, 1, a:options.inner))
    call to.end(self.get_boundary(pos))
  elseif self.boundary_kind(boundary) == 'end'
    "echom 'c.fto: '.3
    call to.end(boundary)
    call pos.position(self.find_from(a:pos, 0, a:options.inner))
    call to.start(self.get_boundary(pos))
  else
    "echom 'c.fto: '.4
    call pos.position(self.find_from(a:pos, 0, a:options.inner))
    call to.start(self.get_boundary(pos))
    call pos.position(self.find_from(a:pos, 1, a:options.inner))
    call to.end(self.get_boundary(pos))
  endif
  return to
endfunction "c.find_text_object

" c.expand_text_object(to, options) dict abort "{{{3
" Ditto
function! c.expand_text_object(to, options) dict
  "echo 'c.eto: a:to => '.a:to.to_s()
  let to = self.objects.new('text_object')
  let kind = self.text_object_kind(a:to)
  if kind == 'top' || kind == 'middle'
    "echo 1
    call to.start(a:to.start())
    call to.end(self.push_boundary(a:to.end(), 1, a:options.inner))
  elseif kind == 'bottom'
    "echo 2
    call to.start(self.push_boundary(a:to.start(), 0, a:options.inner))
    call to.end(a:to.end())
  elseif kind == 'whole'
    "echo 3
    call to.start(self.push_boundary(a:to.start(), 0, a:options.inner))
    call to.end(self.push_boundary(a:to.end(), 1, a:options.inner))
  else
    "echo 4
    return self.objects.new('text_object')
  endif
  if to.equal(a:to)
    return self.objects.new('text_object')
  endif
  return to
endfunction "c.expand_text_object

" c.find_at(position) dict abort "{{{3
" Determine which pattern is found at the given position, if any.
function! c.find_at(position) dict
  " Position cursor
  call cursor(a:position.position())
  let result = ['', -1]
  " Should the current position be skipped?
  if eval(self.skip)
    return result
  endif
  "TODO: Why 'end' is not detected?
  for kind in keys(filter(copy(self.patterns), 'v:val != ""'))
    if searchpos(self.patterns[kind], "cn", line(".")) == a:position.position()
      let result = [kind, 1]
      "echom 'c.fa: result => ' . string(result)
      break
    endif
    if searchpos(self.patterns[kind], "cne", line(".")) == a:position.position()
      let result = [kind, 0]
      "echom 'c.fa: result => ' . string(result)
      break
    endif
  endfor
  "echom 'c.fa: result => ' . string(result)
  return result
endfunction "c.find_at

" c.find_from(pos, forward, middle, ...) dict abort "{{{3
" Looks for a pair and returns its position.
function! c.find_from(pos, forward, inner, ...) dict
  call cursor(a:pos)
  let pos = self.objects.new('position')
  let f_b = a:forward ? '' : 'b'
  let [matchHere, start] = self.find_at(a:pos)
  "echom 'c.ff: matchHere => ' . matchHere . ', forward => '. a:forward . ', inner => '. a:inner
  if matchHere == 'start' && a:forward
    "echom 'c.ff: 1'
    let f_c = ''
  elseif matchHere == 'middle'
    "echom 'c.ff: 2'
    let f_c = ''
  elseif matchHere == 'end' && !a:forward
    "echom 'c.ff: 3'
    if !start
      " searchpair() doesn't detect the 'end' word under the cursor unles it's on
      " thecursor is at the beggining of it.
      call search(self.patterns.end, "cb", line("."))
    endif
    let f_c = ''
  else
    "echom 'c.ff: 4'
    let f_c = a:0 && a:1 ? 'c' : ''
  endif
  let flags = 'Wn'.f_b.f_c
  "echom 'c.ff: flags => ' . flags
  let middle = (a:inner || get(self, 'always_middle', 0) ? self.patterns.middle : '')
  call pos.position(searchpairpos(self.patterns.start, middle, self.patterns.end, flags, self.skip))
  return pos
endfunction "c.find_from

" c.get_boundary(pos) dict abort "{{{3
" Ditto
function! c.get_boundary(pos) dict
  let boundary = self.objects.new('boundary')
  let in = 0
  if !a:pos.valid()
    return boundary
  endif
  " Position cursor
  call cursor(a:pos.position())
  let pos1 = self.objects.new('position')
  let pos2 = self.objects.new('position')
  for kind in keys(filter(copy(self.patterns), 'v:val != ""'))
    call pos1.position(searchpos(self.patterns[kind], 'Wcb', 0, 100))
    if !pos1.valid() || eval(self.skip)
      call cursor(a:pos.position())
      continue
    endif
    call pos2.position(searchpos(self.patterns[kind], 'Wcne', 0, 100))
    if pos2.before(a:pos)
      call cursor(a:pos.position())
      continue
    endif
    let in = 1
    break
  endfor
  if !in
    return boundary
  endif
  call boundary.first(pos1)
  call boundary.last(pos2)
  return boundary
endfunction "c.get_boundary

" c.boundary_kind(boundary) dict abort "{{{3
" Ditto
function! c.boundary_kind(boundary) dict
  call cursor(a:boundary.first().to_l())
  let pos = self.objects.new('position')
  for kind in keys(filter(copy(self.patterns), 'v:val != ""'))
    call pos.position(searchpos(self.patterns[kind], 'Wcn', 0, 100))
    if pos.valid() && pos.equal(a:boundary.first())
      return kind
    endif
  endfor
  return ''
endfunction "c.boundary_kind

" c.text_object_kind(to) dict abort "{{{3
" Ditto
function! c.text_object_kind(to) dict
  if self.boundary_kind(a:to.start()) == 'start' && self.boundary_kind(a:to.end()) == 'middle'
    return 'top'
  elseif self.boundary_kind(a:to.start()) == 'middle' && self.boundary_kind(a:to.end()) == 'end'
    return 'bottom'
  elseif self.boundary_kind(a:to.start()) == 'middle' && self.boundary_kind(a:to.end()) == 'middle'
    return 'middle'
  elseif self.boundary_kind(a:to.start()) == 'start' && self.boundary_kind(a:to.end()) == 'end'
    return 'whole'
  else
    return ''
  endif
endfunction "c.text_object_kind

" c.choose_text_object(to1, to2) dict abort "{{{3
" Ditto
function! c.choose_text_object(to1, to2) dict
  if empty(a:to1) || empty(a:to2)
    return self.objects.new('text_object')
  endif
  if a:to1.equal(a:to2)
    return a:to1
  endif
  if a:to1.contains(a:to2)
    return a:to1
  elseif a:to2.contains(a:to1)
    return a:to2
  else
    return self.objects.new('text_object')
  endif
endfunction "c.choose_text_object

" c.push_boundary(boundary, forward, inner) dict abort "{{{3
" Ditto
function! c.push_boundary(boundary, forward, inner) dict
  let pos = self.find_from(a:boundary.first(), a:forward, a:inner)
  return self.get_boundary(pos)
endfunction "c.push_boundary

" Library functions. {{{1
" textobj#reggie#setup(options) "{{{2
" Ditto
function! textobj#reggie#setup(...)
  return call(g:c.tools.setup, a:000, g:c.tools)
endfunction "textobj#reggie#setup

" textobj#reggie#handle_mapping(...) "{{{2
" Ditto
function! textobj#reggie#handle_mapping(...)
  "redir => g:log
  let result = call(g:c.tools.handle_mapping, a:000, g:c.tools)
  "echo ' '
  "echom result
  "echo ' '
  "echo g:c.tools
  "redir END
  return result
endfunction "textobj#reggie#handle_mapping

" textobj#reggie#get_dictionary() "{{{2
" Ditto
function! textobj#reggie#get_dictionary()
  return deepcopy(g:c)
endfunction "textobj#reggie#get_dictionary

