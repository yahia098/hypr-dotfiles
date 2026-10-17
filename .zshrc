export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git)
source $ZSH/oh-my-zsh.sh
alias dmusic="~/Codes/download-music.sh"
alias dvideo="~/Codes/download-video.sh"
alias esp=". /opt/esp-idf/export.sh"
alias zathura="zathura --fork "
alias ls="lsd"
export EDITOR='nvim'
export TV_IP="192.168.1.71"
export PHONE_IP="192.168.1.66"
function y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
    command rm -f -- "$tmp"
}

