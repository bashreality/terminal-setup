# Core shell behavior, history, and PATH.

typeset -U path PATH
path=(${path:#${HOME}/.local/share/zinit/plugins/*})
path=(${path:#${HOME}/.local/share/zinit/polaris/bin})
path=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  "$HOME/.local/bin"
  "$HOME/.antigravity/antigravity/bin"
  $path
)
export PATH

export LANG="${LANG:-en_US.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-UTF-8}"
export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"
export LESS='-FRX'

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt \
  APPEND_HISTORY \
  EXTENDED_HISTORY \
  HIST_EXPIRE_DUPS_FIRST \
  HIST_FIND_NO_DUPS \
  HIST_IGNORE_ALL_DUPS \
  HIST_IGNORE_SPACE \
  HIST_REDUCE_BLANKS \
  HIST_SAVE_NO_DUPS \
  INTERACTIVE_COMMENTS \
  SHARE_HISTORY

unsetopt BEEP
bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
