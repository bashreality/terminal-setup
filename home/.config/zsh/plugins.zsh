# Zinit manages shell behavior only. Command-line programs come from Homebrew.

typeset zinit_home="$HOME/.local/share/zinit/zinit.git"
if [[ -r "$zinit_home/zinit.zsh" ]]; then
  source "$zinit_home/zinit.zsh"

  # Ignore stale completion links left by the previous binary-managed setup.
  fpath=(${fpath:#$HOME/.local/share/zinit/completions})

  _zinit_load_local() {
    local repository="$1"
    local plugin_dir="$HOME/.local/share/zinit/plugins/${repository//\//---}"
    [[ -d $plugin_dir ]] || return 0
    zinit light "$repository"
  }

  # Completion definitions must extend fpath before compinit runs.
  _zinit_load_local zsh-users/zsh-completions

  autoload -Uz compinit
  typeset zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
  command mkdir -p -- "${zcompdump:h}"
  if [[ -n "$zcompdump"(#qN.mh+24) ]]; then
    compinit -d "$zcompdump"
  else
    compinit -C -d "$zcompdump"
  fi

  zstyle ':completion:*' completer _complete _match _approximate
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
  zstyle ':completion:*' menu select
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS:-}"
  zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
  zstyle ':completion:*' group-name ''

  _zinit_load_local Aloxaf/fzf-tab
  zstyle ':fzf-tab:*' fzf-pad 2
  zstyle ':fzf-tab:complete:cd:*' fzf-preview \
    'eza --tree --level=2 --icons=auto -- "$realpath" 2>/dev/null || command ls -la -- "$realpath"'
  zstyle ':fzf-tab:complete:__git:*' fzf-preview 'git diff --color=always -- "$word" 2>/dev/null'

  _zinit_load_local junegunn/fzf-git.sh
  _zinit_load_local zsh-users/zsh-autosuggestions
  ZSH_AUTOSUGGEST_USE_ASYNC=1
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40

  # Syntax highlighting must be the final ZLE plugin.
  _zinit_load_local zdharma-continuum/fast-syntax-highlighting
else
  _zinit_load_local() { return 0; }
  autoload -Uz compinit
  compinit -C
fi

# Zinit replays historical PATH changes from its plugin metadata. Keep only
# Homebrew and user-managed command paths after loading shell plugins.
path=(${path:#${HOME}/.local/share/zinit/plugins/*})
path=(${path:#${HOME}/.local/share/zinit/polaris/bin})
typeset -U path PATH
rehash

unset zinit_home zcompdump
