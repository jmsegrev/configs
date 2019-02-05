# byogu vim color
export TERM="xterm-256color"
 
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/Workspace/go
export PATH=$PATH:$GOPATH/bin

export JAVA_HOME=$(update-alternatives --query javac | sed -n -e 's/Best: *\(.*\)\/bin\/javac/\1/p')
export ANDROID_HOME=~/android
export PATH=$PATH:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools

export PATH=$PATH:$HOME/.yarn/bin

export PATH=$PATH:$HOME/.pub-cache/bin
export PATH=$PATH:$HOME/.appimages/

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
EDITOR=nvim


alias vim="nvim"

alias byobu-new="tmux new-session -s"
