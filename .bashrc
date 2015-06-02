# byogu vim color
export TERM="xterm-256color"

# Golang
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/Workspace/go
export PATH=$PATH:$GOPATH/bin


source /usr/lib/git-core/git-sh-prompt

# bash promt
if [[ $EUID -eq 0 ]]; then
  RED='\e[0;31m'
  GREEN='\e[0;32m'
  NC='\e[0m'
  GIT_BRANCH='$(__git_ps1 "(%s)")'
  GVM='$(gvm-prompt "(%s)")'
  PS1="[${RED}\u \T \w \t.\d${GREEN}${GIT_BRANCH}$NC]\n >"
else
  RED='\e[0;31m'
  GREEN='\e[0;32m'
  NC='\e[0m'
  GIT_BRANCH='$(__git_ps1 "(%s)")'
  GVM='$(gvm-prompt "(%s)")'
  PS1="[${GREEN}\u \T \w ${RED}${GIT_BRANCH}$NC]\n > "
fi
EDITOR=vim
