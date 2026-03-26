if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
ZSH=/usr/share/oh-my-zsh/
ZSH_THEME="robbyrussell"
plugins=(git)
ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source $ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export EDITOR=nvim
alias ls="lsd"
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
HISTFILE=~/.config/zsh/.ZSH_HISTFILE
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory inc_append_history extended_history

