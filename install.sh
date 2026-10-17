#!/usr/bin/env bash
# ==============================================================================
# terminal-setup — odtwarza terminal 1:1 na nowym Macu
#
#   ./install.sh                 pełna instalacja (brew + aplikacje + configi + pluginy)
#   ./install.sh --dry-run       pokaż, co zostanie zrobione, nic nie zmieniaj
#   ./install.sh --copy          kopiuj configi zamiast robić symlinki do repo
#   ./install.sh --skip-brew     pomiń Homebrew i pakiety (tylko configi + pluginy)
#   ./install.sh --skip-apps     pomiń aplikacje z Brewfile.apps (Ghostty, iTerm2, OrbStack)
#   ./install.sh --skip-tests    pomiń test konfiguracji zsh na końcu
#
# Działa z /bin/bash 3.2 (domyślny bash na macOS).
# ==============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_SRC="$REPO_DIR/home"
BACKUP_DIR="$HOME/.terminal-setup-backup/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
LINK_MODE=symlink
SKIP_BREW=0
SKIP_APPS=0
SKIP_TESTS=0

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; }

while (( $# )); do
  case "$1" in
    --dry-run)    DRY_RUN=1 ;;
    --copy)       LINK_MODE=copy ;;
    --skip-brew)  SKIP_BREW=1 ;;
    --skip-apps)  SKIP_APPS=1 ;;
    --skip-tests) SKIP_TESTS=1 ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Nieznana opcja: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ -t 1 ]]; then
  BLUE=$'\033[0;34m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m' RED=$'\033[0;31m' CYAN=$'\033[0;36m' NC=$'\033[0m'
else
  BLUE='' GREEN='' YELLOW='' RED='' CYAN='' NC=''
fi

info()    { printf '%s[*]%s %s\n' "$BLUE" "$NC" "$*"; }
success() { printf '%s[✓]%s %s\n' "$GREEN" "$NC" "$*"; }
warn()    { printf '%s[!]%s %s\n' "$YELLOW" "$NC" "$*"; }
die()     { printf '%s[✗]%s %s\n' "$RED" "$NC" "$*" >&2; exit 1; }
step()    { printf '\n%s==> %s%s\n' "$CYAN" "$*" "$NC"; }

# Wykonuje polecenie albo tylko je wypisuje w trybie --dry-run.
run() {
  if (( DRY_RUN )); then
    printf '    would run: %s\n' "$*"
  else
    "$@"
  fi
}

[[ "$(uname -s)" == Darwin ]] || die "Ten setup jest dla macOS."

# ------------------------------------------------------------------------------
step "1/8  Xcode Command Line Tools"
# ------------------------------------------------------------------------------
if xcode-select -p >/dev/null 2>&1; then
  success "Command Line Tools są zainstalowane"
else
  warn "Brak Command Line Tools — otwieram instalator systemowy."
  run xcode-select --install || true
  (( DRY_RUN )) || die "Dokończ instalację Command Line Tools i uruchom ./install.sh ponownie."
fi

# ------------------------------------------------------------------------------
step "2/8  Homebrew"
# ------------------------------------------------------------------------------
load_brew() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x $candidate ]]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

if (( SKIP_BREW )); then
  warn "Pominięto (--skip-brew)"
  load_brew || true
else
  if ! load_brew; then
    info "Instaluję Homebrew..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (( DRY_RUN )) || load_brew || die "Homebrew nie został znaleziony po instalacji."
  fi
  [[ "$(uname -m)" == arm64 ]] || warn "Configi zakładają Apple Silicon (/opt/homebrew). Na Intelu sprawdź ścieżki w core.zsh i .gitconfig."
  success "Homebrew: $(command -v brew || echo 'zostanie zainstalowany')"
fi

# ------------------------------------------------------------------------------
step "3/8  uv (Astral, instalacja w ~/.local/bin jak na źródłowym Macu)"
# ------------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
if (( SKIP_BREW )); then
  warn "Pominięto (--skip-brew)"
elif command -v uv >/dev/null 2>&1; then
  success "uv już jest: $(command -v uv)"
else
  run /bin/sh -c "curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh"
  success "uv zainstalowany"
fi

# ------------------------------------------------------------------------------
step "4/8  Pakiety Homebrew (Brewfile$( (( SKIP_APPS )) || echo ' + Brewfile.apps'))"
# ------------------------------------------------------------------------------
bundle() {
  local file="$1"
  # Bundle kontynuuje po pojedynczych błędach; podsumowanie i tak trafia na ekran.
  if ! run brew bundle --file="$file"; then
    warn "Część pozycji z $(basename "$file") się nie zainstalowała — sprawdź log powyżej."
  fi
}

if (( SKIP_BREW )); then
  warn "Pominięto (--skip-brew)"
else
  export HOMEBREW_NO_ANALYTICS=1
  bundle "$REPO_DIR/Brewfile"
  if (( SKIP_APPS )); then
    warn "Pominięto aplikacje (--skip-apps)"
  else
    bundle "$REPO_DIR/Brewfile.apps"
  fi
  success "Pakiety gotowe"
fi

# ------------------------------------------------------------------------------
step "5/8  Pliki konfiguracyjne ($LINK_MODE)"
# ------------------------------------------------------------------------------
backed_up=0

backup() {
  local target="$1" rel="$2"
  run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
  run mv "$target" "$BACKUP_DIR/$rel"
  backed_up=1
  printf '    backup: ~/%s\n' "$rel"
}

install_file() {
  local src="$1" rel="$2"
  local dst="$HOME/$rel"

  if [[ $LINK_MODE == symlink && -L $dst && "$(readlink "$dst")" == "$src" ]]; then
    printf '    ok:     ~/%s\n' "$rel"
    return
  fi
  if [[ $LINK_MODE == copy && -f $dst && ! -L $dst ]] && cmp -s "$src" "$dst"; then
    printf '    ok:     ~/%s\n' "$rel"
    return
  fi

  run mkdir -p "$(dirname "$dst")"
  if [[ -e $dst || -L $dst ]]; then
    backup "$dst" "$rel"
  fi
  if [[ $LINK_MODE == symlink ]]; then
    run ln -s "$src" "$dst"
  else
    run cp -p "$src" "$dst"
  fi
  printf '    %s:   ~/%s\n' "$( [[ $LINK_MODE == symlink ]] && echo link || echo copy)" "$rel"
}

while IFS= read -r -d '' src; do
  install_file "$src" "${src#"$HOME_SRC"/}"
done < <(find "$HOME_SRC" -type f ! -name .DS_Store -print0 | sort -z)

# Skompilowany .zshrc.zwc nowszy niż .zshrc zostałby użyty zamiast nowej konfiguracji.
if [[ -e $HOME/.zshrc.zwc ]]; then
  backup "$HOME/.zshrc.zwc" .zshrc.zwc
fi

# atuin trzyma config z uprawnieniami 600 — zachowujemy to.
[[ -e $HOME_SRC/.config/atuin/config.toml ]] && run chmod 600 "$HOME_SRC/.config/atuin/config.toml"

(( backed_up )) && warn "Poprzednie pliki przeniesione do: $BACKUP_DIR"
success "Configi na miejscu"

# ------------------------------------------------------------------------------
step "6/8  Pluginy zsh (zinit) i tmux — przypięte do commitów z plugins.lock"
# ------------------------------------------------------------------------------
command -v git >/dev/null 2>&1 || die "Brak git."

sync_plugin() {
  local rel="$1" url="$2" commit="$3"
  local dir="$HOME/$rel"

  if [[ ! -d $dir/.git ]]; then
    if [[ -e $dir ]]; then
      backup "$dir" "$rel"
    fi
    run mkdir -p "$(dirname "$dir")"
    run git clone --quiet "$url" "$dir"
  fi
  if (( ! DRY_RUN )) && [[ "$(git -C "$dir" rev-parse HEAD)" == "$commit" ]]; then
    printf '    ok:     %s @ %s\n' "${rel##*/}" "${commit:0:7}"
    return
  fi
  if (( ! DRY_RUN )) && ! git -C "$dir" cat-file -e "$commit^{commit}" 2>/dev/null; then
    git -C "$dir" fetch --quiet origin
  fi
  run git -C "$dir" -c advice.detachedHead=false checkout --quiet "$commit"
  printf '    pin:    %s @ %s\n' "${rel##*/}" "${commit:0:7}"
}

while read -r rel url commit; do
  [[ -z ${rel:-} || $rel == \#* ]] && continue
  sync_plugin "$rel" "$url" "$commit"
done < "$REPO_DIR/plugins.lock"
success "Pluginy gotowe"

# ------------------------------------------------------------------------------
step "7/8  Dodatki: ściągawki navi, profil iTerm2"
# ------------------------------------------------------------------------------
if command -v navi >/dev/null 2>&1; then
  cheats_dir="$(navi info cheats-path 2>/dev/null || echo "$HOME/.local/share/navi/cheats")/denisidoro__cheats"
  if [[ -d $cheats_dir ]]; then
    printf '    ok:     navi cheats (%s)\n' "$cheats_dir"
  else
    run git clone --quiet --depth 1 https://github.com/denisidoro/cheats "$cheats_dir"
    printf '    clone:  navi cheats\n'
  fi
else
  warn "navi niedostępne — pomijam ściągawki"
fi

iterm_profile="$REPO_DIR/extras/iterm2/profile.json"
iterm_dynamic="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
if [[ -d /Applications/iTerm.app || -d $iterm_dynamic ]]; then
  run mkdir -p "$iterm_dynamic"
  run cp "$iterm_profile" "$iterm_dynamic/bashreality.json"
  guid="$(/usr/bin/plutil -extract Profiles.0.Guid raw -o - "$iterm_profile")"
  run defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$guid"
  printf '    iTerm2: profil "bashreality" ustawiony jako domyślny\n'
else
  printf '    iTerm2 nie jest zainstalowany — pomijam profil\n'
fi

# ------------------------------------------------------------------------------
step "8/8  Domyślny shell i test konfiguracji"
# ------------------------------------------------------------------------------
current_shell="$( { dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null || true; } | awk '{print $2}')"
if [[ $current_shell == */zsh ]]; then
  success "Domyślny shell: $current_shell"
else
  run chsh -s /bin/zsh
  success "Domyślny shell zmieniony na /bin/zsh"
fi

if (( SKIP_TESTS || DRY_RUN )); then
  warn "Test pominięty"
elif /bin/zsh "$HOME/.config/zsh/tests/test_zsh_config.zsh"; then
  success "Test konfiguracji zsh przeszedł"
else
  warn "Test konfiguracji zsh zgłosił problem (zwykle brakujący pakiet z Brewfile)."
fi

cat <<EOF

${GREEN}Gotowe.${NC} Otwórz nowe okno Ghostty (albo: exec zsh).
  • Czcionki: JetBrainsMono Nerd Font (Ghostty), MesloLGS Nerd Font (iTerm2)
  • tmux: prefix Ctrl+A, pluginy już zainstalowane
  • Lokalne nadpisania (niewersjonowane): ~/.config/zsh/local.zsh
EOF
