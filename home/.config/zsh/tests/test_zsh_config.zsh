#!/bin/zsh

setopt ERR_EXIT NO_UNSET PIPE_FAIL

typeset -r config_root="${ZSH_CONFIG_HOME:-$HOME/.config/zsh}"
typeset -r zshrc="$HOME/.zshrc"
typeset -a module_files=(
  core.zsh
  plugins.zsh
  tools.zsh
  aliases.zsh
  functions.zsh
  kubernetes.zsh
  cloud.zsh
  security.zsh
)

fail() {
  print -u2 -- "FAIL: $*"
  return 1
}

for module in $module_files; do
  [[ -r "$config_root/$module" ]] || fail "missing module: $module"
done

zsh -n "$zshrc" "$config_root"/*.zsh || fail "configuration has invalid syntax"

if command grep -Eq 'git clone|zinit update|zcompile|terraform -install-autocomplete|nvm\.sh|pyenv init' "$zshrc" "$config_root"/*.zsh; then
  fail "startup configuration performs installation, updates, compilation, or legacy runtime initialization"
fi

if command grep -Eq "alias[[:space:]]+(kill|find|grep|ps|du|df|ping|cat)=" "$zshrc" "$config_root"/*.zsh; then
  fail "configuration replaces a standard command with incompatible behavior"
fi

if command grep -Eq 'sudo[[:space:]]+command[[:space:]]' "$zshrc" "$config_root"/*.zsh; then
  fail "configuration asks sudo to execute the shell-only command builtin"
fi

typeset stderr_file="$(mktemp -t zsh-config-test.XXXXXX)"
trap 'command rm -f -- "$stderr_file"' EXIT

TERM_PROGRAM=Codex zsh -dfic '
  source "$HOME/.zshrc" >/dev/null
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  (( $+commands[starship] ))
  (( $+commands[atuin] ))
  (( $+commands[fzf] ))
  (( $+commands[zoxide] ))
  (( $+commands[mise] ))

  (( $+functions[fkill] ))
  (( $+functions[mkcd] ))
  (( $+functions[extract] ))
  (( $+functions[kswitchns] ))
  (( $+functions[gcpswitch] ))
  (( $+functions[portscan] ))
  (( $+functions[recon] ))
  (( $+functions[analyze-failed-logins] ))
  (( $+functions[_zinit_load_local] ))

  typeset missing_plugin="$HOME/.local/share/zinit/plugins/codex-test---missing-plugin"
  [[ ! -e $missing_plugin ]]
  _zinit_load_local codex-test/missing-plugin
  [[ ! -e $missing_plugin ]]

  [[ -z ${aliases[kill]-} ]]
  [[ ${aliases[h]-} == history ]]
  [[ ${aliases[k]-} == kubectl ]]
  [[ ${aliases[g]-} == git ]]

  [[ ${commands[atuin]} == /opt/homebrew/bin/atuin ]]
  for path_entry in $path; do
    [[ $path_entry != $HOME/.local/share/zinit/plugins/* ]]
    [[ $path_entry != $HOME/.local/share/zinit/polaris/bin ]]
  done

  typeset -a unique_path=("${(@u)path}")
  (( ${#path} == ${#unique_path} ))
' 2>"$stderr_file" || fail "interactive shell contract failed"

[[ ! -s "$stderr_file" ]] || {
  command cat "$stderr_file" >&2
  fail "interactive shell writes to stderr"
}

print -- "PASS: zsh configuration contract"
