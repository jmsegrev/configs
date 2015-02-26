set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'


" Go
Bundle 'fatih/vim-go'
" Class/module browser
Bundle 'majutsushi/tagbar'
" Colorscheme
Bundle 'nanotech/jellybeans.vim'
" Yank history navigation
Bundle 'YankRing.vim'
" Zen coding
Bundle 'mattn/emmet-vim'
" Git diff icons on the side of the file lines
Bundle 'airblade/vim-gitgutter'
" Ligthline
Bundle 'itchyny/lightline.vim'
" Python mode
Bundle 'klen/python-mode'
" XML/HTML tags navigation
Bundle 'matchit.zip'
" Text alignment
Plugin 'godlygeek/tabular'
" Marckdown highlighter
Plugin 'plasticboy/vim-markdown'
" Textile highligther
Plugin 'timcharper/textile.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
"

colorscheme jellybeans

" tabs
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" incremental search
set incsearch

" highlighted search results
set hlsearch

" syntax highlight on
syntax on

" line numbers
set nu

" Better backup, swap and undos storage
set directory=~/.vim/dirs/tmp     " directory to place swap files in
set backup                        " make backup files
set backupdir=~/.vim/dirs/backups " where to put backup files
set undofile                      " persistent undos - undo after you re-open the file
set undodir=~/.vim/dirs/undos
set viminfo+=n~/.vim/dirs/viminfo
" store yankring history file there too
let g:yankring_history_dir = '~/.vim/dirs'

" lightline settings
set laststatus=2
let g:lightline = {
\ 'colorscheme': 'jellybeans',
\ }

" go-vim
au FileType go nmap <Leader>i <Plug>(go-info)
let g:go_fmt_command = "goimports"

let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1

" docs
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)

" open code definition 
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)

" python-mode
set nofoldenable
let g:pymode_rope = 0
" personal ->

"highlight ExtraWhitespace ctermbg=red guibg=red

"match ExtraWhitespace /\s\+$/

ca rmbs :%s/\s\+$//gc<CR>
ca rmcr :%s/\r//gc<CR>

" change the leader to be a comma vs slash
"let mapleader=","  

" navigate windows
imap <C-S-l> <ESC><c-w>l
imap <C-S-h> <ESC><c-w>h
imap <C-S-k> <ESC><c-w>k
imap <C-S-j> <ESC><c-w>j


" autocmd FileType python set colorcolumn=79

map <leader>v :tabe ~/.vimrc<CR>

map <silent> <leader>V :source ~/.vimrc<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>

"cmap w!! w !sudo tee % >/dev/null

map <leader>w :pwd<CR>

" number line toggle
nmap <leader>n :set invnumber<CR>
" paste mode toggle
nmap <leader>p :set invpaste<CR>

set cursorline

" tab navigation 
nmap <S-z> :tabp<CR>
nmap <S-x> :tabn<CR>

" tab navigation 2
nmap <C-h> :tabp<CR>
nmap <C-l> :tabn<CR>


" char limit indicator
set colorcolumn=79

" text wrap at 79
set textwidth=79

" nice complete on esc mode
set wildmode=list:longest
