# byogu vim color
export TERM="xterm-256color"

# Golang
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/Workspace/go
export PATH=$PATH:$GOPATH/bin


source /usr/lib/git-core/git-sh-prompt

# bash promt
RED='\e[0;31m'
GREEN='\e[0;32m'
NC='\e[0m'
GVM='$(gvm-prompt "(%s)")'
GIT_BRANCH='$(__git_ps1 "(%s)")'
PROMPT="[${GREEN}\u \T \w ${RED}${GIT_BRANCH}$NC]\n"
if [[ $EUID -eq 0 ]]; then
  PS1="${PROMPT} # "
else
  PS1="${PROMPT} $ "
fi
EDITOR=vim
