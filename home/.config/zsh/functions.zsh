# General-purpose interactive helpers.

mkcd() {
  (( $# == 1 )) || { print -u2 -- 'usage: mkcd <directory>'; return 2; }
  command mkdir -p -- "$1" && builtin cd -- "$1"
}

extract() {
  (( $# == 1 )) || { print -u2 -- 'usage: extract <archive>'; return 2; }
  [[ -f $1 ]] || { print -u2 -- "extract: not a file: $1"; return 1; }

  case $1 in
    *.tar.bz2|*.tbz2) command tar -xjf "$1" ;;
    *.tar.gz|*.tgz)   command tar -xzf "$1" ;;
    *.tar.xz|*.txz)   command tar -xJf "$1" ;;
    *.tar)            command tar -xf "$1" ;;
    *.bz2)            command bunzip2 "$1" ;;
    *.gz)             command gunzip "$1" ;;
    *.rar)            command unrar x "$1" ;;
    *.zip)            command unzip "$1" ;;
    *.7z)             command 7z x "$1" ;;
    *) print -u2 -- "extract: unsupported archive: $1"; return 1 ;;
  esac
}

cdd() {
  (( $+commands[zoxide] && $+commands[fzf] )) || {
    print -u2 -- 'cdd requires zoxide and fzf'
    return 1
  }

  local directory
  directory="$(zoxide query --list | fzf \
    --prompt='directory> ' \
    --preview='eza --tree --level=2 --icons=auto -- {} 2>/dev/null || command ls -la -- {}')" || return
  [[ -n $directory ]] && builtin cd -- "$directory"
}

fkill() {
  (( $+commands[fzf] )) || { print -u2 -- 'fkill requires fzf'; return 1; }

  local signal=TERM
  if [[ ${1:-} == -9 || ${1:-} == --force ]]; then
    signal=KILL
    shift
  fi

  local selection pid
  selection="$(command ps -Ao pid=,user=,%cpu=,%mem=,command= | fzf \
    --query="${*:-}" --header="Select process to send SIG$signal")" || return
  pid="${${(z)selection}[1]}"
  [[ $pid == <-> ]] || { print -u2 -- 'fkill: invalid process selection'; return 1; }
  command kill "-$signal" "$pid"
}

top-memory() {
  command ps -Ao pid,user,%mem,rss,command -r | command head -21
}

top-cpu() {
  command ps -Ao pid,user,%cpu,command -r | command head -21
}

genpass() {
  local length="${1:-24}"
  [[ $length == <1-9><-> || $length == <1-9> ]] || {
    print -u2 -- 'usage: genpass [positive-length]'
    return 2
  }
  command openssl rand -base64 "$(( length * 2 ))" | command tr -dc 'A-Za-z0-9_-' | command head -c "$length"
  print
}

b64encode() {
  print -rn -- "$1" | command openssl base64 -A
}

b64decode() {
  print -rn -- "$1" | command openssl base64 -d -A
}

urlencode() {
  command python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$1"
}

urldecode() {
  command python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))' "$1"
}

mkvenv() {
  local env_name="${1:-.venv}"
  if (( $+commands[uv] )); then
    uv venv "$env_name" && source "$env_name/bin/activate"
  else
    python3 -m venv "$env_name" && source "$env_name/bin/activate"
  fi
}

pyproject() {
  (( $# == 1 )) || { print -u2 -- 'usage: pyproject <project-name>'; return 2; }
  command mkdir -p -- "$1/src" "$1/tests" "$1/docs" || return
  print -r -- "# $1" >| "$1/README.md"
  print -r -- $'__pycache__/\n*.py[cod]\n.venv/\n.env' >| "$1/.gitignore"
  builtin cd -- "$1" && mkvenv .venv
}
