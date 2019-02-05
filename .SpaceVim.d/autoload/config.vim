func! config#before() abort
  " custom color for tabs and ariline for jellybeans theme
  let g:spacevim_custom_color_palette = [
  \ ['#282828', '#eeeeee', 246, 235],
  \ ['#c7c7c7', '#504945', 239, 246],
  \ ['#c7c7c7', '#3c3836', 237, 246],
  \ ['#665c54', 241],
  \ ['#282828', '#70b950', 235, 109],
  \ ['#282828', '#ffcc33', 235, 208],
  \ ['#282828', '#8ec07c', 235, 108],
  \ ['#282828', '#70b950', 235, 72],
  \ ['#282828', '#ffcc33', 235, 132],
  \ ]

  let g:spacevim_auto_disable_touchpad = 0

  let g:ale_fixers = {
  \   'typescript': ['prettier', 'tslint'],
  \}
  let g:ale_fix_on_save = 1
  let g:ale_lint_delay = 0
  let g:ale_linters = {
  \   'typescript': ['tsserver'],
  \}
  let g:nvim_typescript#diagnostics_enable = 0

  highlight clear ALEErrorSign
  highlight clear ALEWarningSign

  highlight link ALEErrorSign GruvboxRedSign
  highlight link ALEWarningSign GruvboxYellowSign

  let g:neoformat_enabled_python = ['yapf']

  " change format of gina blame
  let g:gina#command#blame#formatter#format = "%ti by %au"
  " store yankring history file in custom spacevim dir
  let g:yankring_history_dir = '~/.SpaceVim.d'

  " override SpaceVim comment highlight
  au VimEnter * hi Comment guifg=#888888 ctermfg=NONE guibg=NONE ctermbg=NONE gui=NONE

  " tab navigation 
  nnoremap <C-h> :bp<CR>
  nnoremap <C-l> :bnext<CR> 


endf

func! config#after() abort

  " make .gql files read as graphql 
  au BufNewFile,BufRead *.gql set ft=graphql

  " visible line text length limit
  set colorcolumn=80

  " always show sign column
  set signcolumn=yes

endf
