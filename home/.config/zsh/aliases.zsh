# Shortcuts keep the original command semantics available.

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'
alias e='exit'
alias h='history'
alias reload='exec zsh'

alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull --ff-only'
alias gd='git diff'
alias gb='git branch'
alias gco='git switch'
alias gr='git restore'
(( $+commands[lazygit] )) && alias lg='lazygit'
(( $+commands[delta] )) && alias gdelta='git diff | delta'

if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza --icons=auto --group-directories-first --long --header --git'
  alias la='eza --icons=auto --group-directories-first --long --header --all --git'
  alias tree='eza --icons=auto --tree --git-ignore --level=3'
  alias lt='eza --icons=auto --tree --git-ignore --level=2'
fi

(( $+commands[bat] )) && alias catt='bat'
(( $+commands[rg] )) && alias grepr='rg'
(( $+commands[fd] )) && alias findf='fd'
(( $+commands[btop] )) && alias topx='btop'
(( $+commands[procs] )) && alias psx='procs'
(( $+commands[dust] )) && alias dux='dust'
(( $+commands[duf] )) && alias dfx='duf'
(( $+commands[doggo] )) && alias digx='doggo'
(( $+commands[gping] )) && alias pingx='gping'
(( $+commands[xh] )) && alias http='xh'
(( $+commands[hyperfine] )) && alias bench='hyperfine'
(( $+commands[yazi] )) && alias ya='yazi'
(( $+commands[fastfetch] )) && alias ff='fastfetch'
(( $+commands[glow] )) && alias md='glow'
(( $+commands[tldr] )) && alias help='tldr'

if (( $+commands[trash] )); then
  alias rm='trash'
fi

if (( $+commands[tmux] )); then
  export TMUX_CONF="$HOME/.config/tmux/tmux.conf"
  alias t='tmux -f $TMUX_CONF'
  alias ta='tmux -f $TMUX_CONF attach'
  alias tn='tmux -f $TMUX_CONF new -s'
  alias tl='tmux -f $TMUX_CONF ls'
fi

if (( $+commands[docker] )); then
  alias d='docker'
  alias dc='docker compose'
  alias dps='docker ps'
  alias di='docker images'
fi
