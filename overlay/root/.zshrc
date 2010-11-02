autoload -U compinit
compinit

bindkey -e
bindkey $terminfo[kpp] history-beginning-search-backward
bindkey $terminfo[knp] history-beginning-search-forward

export EDITOR=vim
export PS1="[%n@%m %1~] $ "

