# Interactive Zsh configuration. Detailed settings live in ~/.config/zsh.
[[ -o interactive ]] || return

typeset -g ZSH_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

for zsh_module in \
  core.zsh \
  plugins.zsh \
  tools.zsh \
  aliases.zsh \
  functions.zsh \
  kubernetes.zsh \
  cloud.zsh \
  security.zsh; do
  [[ -r "$ZSH_CONFIG_HOME/$zsh_module" ]] && source "$ZSH_CONFIG_HOME/$zsh_module"
done
unset zsh_module

# Machine-local overrides are intentionally not managed here.
[[ -r "$ZSH_CONFIG_HOME/local.zsh" ]] && source "$ZSH_CONFIG_HOME/local.zsh"

# zoxide asks to be initialized after other shell hooks.
if (( $+commands[zoxide] )); then
  export _ZO_EXCLUDE_DIRS="$HOME/.cache:$HOME/.local/share"
  eval "$(zoxide init zsh --cmd z)"
fi

# A reloaded mise session can restore PATH entries captured by the old config.
path=(${path:#${HOME}/.local/share/zinit/plugins/*})
path=(${path:#${HOME}/.local/share/zinit/polaris/bin})
typeset -U path PATH
rehash
