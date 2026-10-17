# Official shell integrations for installed command-line tools.

export USE_NERD_FONTS=1
typeset -i zle_ready=0
[[ -o zle && -t 0 && -t 1 ]] && zle_ready=1

if (( $+commands[vivid] )); then
  export LS_COLORS="$(vivid generate catppuccin-mocha)"
fi

export BAT_THEME="Catppuccin Mocha"
export BAT_STYLE="numbers,changes,header"

if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

export FZF_DEFAULT_OPTS='--height=65% --layout=reverse --border --info=inline --preview-window=right:55%:wrap --bind=ctrl-/:toggle-preview'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range=:300 -- {} 2>/dev/null || command sed -n 1,300p -- {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=auto -- {} 2>/dev/null || command ls -la -- {}'"

if (( zle_ready && $+commands[fzf] )); then
  source <(fzf --zsh)
fi

if (( zle_ready && $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

if (( zle_ready && $+commands[starship] )); then
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
  eval "$(starship init zsh)"
fi

if (( $+commands[op] )); then
  eval "$(op completion zsh)"
fi

if (( zle_ready && $+commands[navi] )); then
  eval "$(navi widget zsh)"
  bindkey '^n' _navi_widget
fi

unset zle_ready
