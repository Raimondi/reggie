" Text-object framework {{{1
let f = {}
let f.name = 'textobj#reggie#'
"let f.criteria = c
" Main functions {{{2
" f.valid_position(pos) dict abort "{{{3
" Ditto
function! f.valid_position(pos) dict
  return a:pos[0] > 0 && a:pos[1] > 0
endfunction "f.valid_position

" f.handle_mapping(options) dict abort "{{{3
" Ditto
function! f.handle_mapping(id, visual, inner, mode) dict
  let s:saved_view = winsaveview()
  let self.current_id = a:id
  let options = self.systems[a:id]
  let options.visual = a:visual
  let options.inner = a:inner
  let options.mode = a:mode
  let options.count = self.get_count(options)
  let [pos1, pos2] = self.criteria.get_positions(options)
  if !self.valid_position(pos1[1:2]) || !self.valid_position(pos2[1:2])
    return self.cancel(options)
  endif
  call self.set_marks(pos1, pos2)
  call winrestview(s:saved_view)
  return self.selection_command(options)
endfunction "f.handle_mapping

" f.setup(settings, ...) dict abort "{{{3
" Ditto
function! f.setup(settings, ...) dict abort
  let options = a:settings
  " Check for an 'id' key.
  if !has_key(a:settings, 'id') || empty(a:settings.id)
    echoe 'Setup: The ''id'' key is either missing or empty!'
  endif
  if !has_key(self.systems, options.id) || a:0
    " Check for patterns.
    if !has_key(a:settings, 'start') || empty(a:settings.start) ||
          \ !has_key(a:settings, 'end') || empty(a:settings.end)
      echoe 'Setup: The ''start'' and/or ''end'' keys are either missing or empty!'
    endif
    " Check for key to map.
    if !has_key(a:settings, 'map_sufix') || empty(a:settings.map_sufix)
      echoe 'Setup: The ''map_sufix'' key is either missing or empty!'
    endif
    call extend(options, self.defaults, 'keep')
    let options.patterns = {}
    let options.patterns.start = options.start
    let options.patterns.middle = options.middle
    let options.patterns.end = options.end
    "TODO: Manage lack of post-processor.
    let self.systems[options.id] = options
    call self.create_plug_mappings(options.id)
  endif
  call self.create_user_mappings(options.id)
  if self.systems[options.id].filetype
    call self.set_undo_ftplugin(options.id)
  endif
endfunction "f.setup

" f.set_undo_ftplugin(id) dict abort "{{{3
" Set the b:undo_ftplugin variable.
function! f.set_undo_ftplugin(id) dict abort
  let local = self.systems[a:id].map_local ? '<buffer> ' : ''
  let undo_ftplugin = ''
  for mode in ['o',self.systems[a:id].map_visual_mode]
    for prefix in ['a', 'i']
      let undo_ftplugin .= 'sil! '
      let undo_ftplugin .= mode . 'unmap '
      let undo_ftplugin .= local
      let undo_ftplugin .= prefix . self.systems[a:id].map_sufix
      let undo_ftplugin .= '| '
    endfor
  endfor
  if exists('b:undo_ftplugin') && b:undo_ftplugin !~ '^\s*$'
    let b:undo_ftplugin = undo_ftplugin . b:undo_ftplugin
  else
    let b:undo_ftplugin = undo_ftplugin[:-3]
  endif
endfunction "f.set_undo_ftplugin

" f.create_plug_mappings(id) dict abort "{{{3
"  Ditto
function! f.create_plug_mappings(id) dict
  "TODO: Put this on the settings as strings to be used after setup.
  for [sufix, inner] in [['a', 0], ['i', 1]]
    let mapping = 'onoremap <expr><Plug>'
    let mapping .= self.name . '-' . a:id . '-o' . sufix . ' '
    let mapping .= self.name . 'handle_mapping('
    let mapping .= string(a:id)
    let mapping .= ', 0, '
    let mapping .= inner
    let mapping .= ", '" . self.systems[a:id].default_mode
    let mapping .= "')"
    execute mapping
    let mapping = 'vnoremap <Plug>'
    let mapping .= self.name . '-' . a:id . '-v' . sufix . ' '
    let mapping .= '<Esc>:exec ' . self.name . 'handle_mapping('
    let mapping .= string(a:id)
    let mapping .= ', 1'
    let mapping .= ', ' . inner
    let mapping .= ', visualmode()'
    let mapping .= ')<CR><Esc>gv'
    execute mapping
  endfor
endfunction "f.create_plug_mappings

" f.create_user_mappings(id) dict abort "{{{3
" Ditto
function! f.create_user_mappings(id) dict
  let local = self.systems[a:id].map_local ? '<buffer> ' : ''
  let mappings = []
  for mode in ['o',self.systems[a:id].map_visual_mode]
    for prefix in ['a', 'i']
      if self.get_options(a:id).overwrite_mappings ||
            \ empty(maparg(prefix . self.systems[a:id].map_sufix, mode))
        let mapping = mode . 'map '
        let mapping .= local . '<silent>'
        let mapping .= prefix . self.systems[a:id].map_sufix . ' '
        let mapping .= '<Plug>' . self.name . '-' . a:id . '-' . mode . prefix
        call add(mappings, mapping)
      else
        echoe 'Create user mappings: A mapping to ''' . prefix . self.systems[a:id].map_sufix . ''' in ' . (mode == 'o' ? 'opreator pending' : 'visual') . ' mode already exists! Aborting.'
        return
      endif
    endfor
  endfor
  for mapping in mappings
    execute mapping
  endfor
endfunction "f.create_user_mappings

" Selection tools {{{2
" f.get_count(options) dict abort "{{{3
" Ditto
function! f.get_count(options) dict
  if a:options.visual
    return v:prevcount == 0 ? 1 : v:prevcount
  else
    return v:count1
  endif
endfunction "f.get_count

" f.cancel(options) dict abort "{{{3
" Ditto
function! f.cancel(options) dict
  call winrestview(s:saved_view)
  return a:options.visual ? '' : "\<Esc>"
endfunction "f.cancel

" f.set_marks(pos1, pos2) dict abort "{{{3
" Ditto
function! f.set_marks(pos1, pos2) dict abort
  return (setpos("'[", a:pos1) + 1) &&
        \ (setpos("']", a:pos2) + 1)
endfunction "f.set_marks

" f.selection_command(options) dict abort "{{{3
" Ditto
function! f.selection_command(options) dict
  if a:options.visual
    return "normal! `[" . a:options.mode . "`]"
  else
    return ":\<C-U>" .
          \ 'exec "normal! `[' .
          \ a:options.mode .
          \ '`]"' .
          \ "\<CR>"
  endif
endfunction "f.selection_command

" Systems {{{2
" TODO: Implement text-objects for any char with getchar() (:h <expr>).
let f.systems                          = {}
let f.defaults                         = {}
let f.defaults.always_middle           = 0
let f.defaults.map_local               = 1
let f.defaults.filetype                = 0
let f.defaults.map_sufix               = ''
let f.defaults.middle                  = ''
let f.defaults.skip                    = ''
let f.defaults.default_mode            = 'v'
let f.defaults.map_visual_mode         = 'v'
let f.defaults.overwrite_mappings      = 0
let f.defaults.linewise                = 0
let f.defaults.post_processor_arg_type = 'l' "one of o, d, l or m
" f.get_options(id) dict abort "{{{3
" Ditto
function! f.get_options(...) dict
  return self.systems[a:0 ? a:1 : self.current_id]
endfunction "f.get_options

" textobj#mapping_tools#new(criteria) abort "{{{1
" Just that.
function! textobj#mapping_tools#new(criteria) abort
  let f = deepcopy(g:f)
  let f.criteria = a:criteria[0]
  return f
endfunction "textobj#mapping_tools#new
