# terminal-setup

Mój terminal na macOS, odtwarzany 1:1 jednym poleceniem: zsh (modułowy config + zinit),
Starship, Ghostty, iTerm2, tmux, atuin, fastfetch, btop i ~50 narzędzi CLI z Homebrew.
Motyw wszędzie: **Catppuccin Mocha**.

## Instalacja na nowym Macu

```bash
xcode-select --install            # jeśli jeszcze nie ma git
git clone https://github.com/bashreality/terminal-setup.git ~/terminal-setup
cd ~/terminal-setup
./install.sh
```

Potem otwórz nowe okno Ghostty. Skrypt można uruchamiać wielokrotnie — to, co już jest
na miejscu, zostaje pominięte.

| Opcja          | Działanie                                                         |
| -------------- | ----------------------------------------------------------------- |
| `--dry-run`    | pokazuje, co zostałoby zrobione, niczego nie zmienia               |
| `--copy`       | kopiuje configi zamiast symlinków do repo                         |
| `--skip-brew`  | pomija Homebrew, uv i pakiety (tylko configi + pluginy)           |
| `--skip-apps`  | pomija Ghostty / iTerm2 / OrbStack z `Brewfile.apps`              |
| `--skip-tests` | pomija test konfiguracji zsh na końcu                             |

### Co robi `install.sh`

1. Sprawdza Xcode Command Line Tools.
2. Instaluje Homebrew (`/opt/homebrew`).
3. Instaluje `uv` do `~/.local/bin` (tak jak na źródłowym Macu).
4. `brew bundle` z `Brewfile` (formuły, czcionki Nerd Font, ngrok, globalne pakiety npm/uv)
   i z `Brewfile.apps` (Ghostty, iTerm2, OrbStack).
5. Linkuje wszystko z `home/` do `~`. Istniejące pliki trafiają do
   `~/.terminal-setup-backup/<data>/`.
6. Klonuje zinit, pluginy zsh i pluginy tmux **dokładnie na commitach** z `plugins.lock`.
7. Pobiera ściągawki navi (`denisidoro/cheats`) i instaluje profil iTerm2 jako domyślny.
8. Sprawdza domyślny shell i uruchamia `~/.config/zsh/tests/test_zsh_config.zsh`.

## Co jest w środku

```
home/
├── .zshrc                     loader modułów z ~/.config/zsh
├── .zprofile                  integracja OrbStack
├── .zshenv                    ~/.cargo/env (tylko jeśli istnieje)
├── .gitconfig                 delta (side-by-side), gh jako credential helper
├── .config/
│   ├── zsh/                   core, plugins, tools, aliases, functions,
│   │                          kubernetes, cloud, security + test
│   ├── starship.toml          prompt, paleta Catppuccin Mocha
│   ├── ghostty/config         motyw, przezroczystość, skróty Cmd+1..9
│   ├── tmux/tmux.conf         prefix Ctrl+A, Catppuccin, resurrect/continuum
│   ├── atuin/config.toml      historia lokalnie, bez synchronizacji
│   ├── btop/btop.conf
│   ├── fastfetch/config.jsonc
│   └── thefuck/settings.py
└── Library/Application Support/com.mitchellh.ghostty/config.ghostty
                               JetBrainsMono Nerd Font 17, Catppuccin Mocha
extras/iterm2/profile.json     profil iTerm2 (MesloLGS NF 18, przezroczystość)
Brewfile                       wynik `brew bundle dump`
Brewfile.apps                  aplikacje spoza Homebrew na źródłowym Macu
plugins.lock                   przypięte commity zinit / pluginów zsh / tmux
```

### Pluginy zsh (zinit)

Zinit tylko **ładuje** lokalnie zainstalowane pluginy — start shella niczego nie pobiera
ani nie aktualizuje (ciepły start ~0,24 s). Ładowane: `zsh-completions`, `fzf-tab`,
`fzf-git.sh`, `zsh-autosuggestions`, `fast-syntax-highlighting`.

Integracje narzędzi: fzf, atuin (Ctrl+R), zoxide (`z`), mise, direnv, starship, navi (Ctrl+N),
vivid (`LS_COLORS`), bat (Catppuccin Mocha).

## Aktualizacja repo po zmianach na tym Macu

```bash
cd ~/terminal-setup
./sync.sh                     # configi + Brewfile + plugins.lock + profil iTerm2
git diff
git commit -am "update" && git push
```

Na Macu zainstalowanym przez `install.sh` configi są symlinkami do repo, więc edycja
`~/.zshrc` od razu zmienia plik w repo — wystarczy commit.

## Celowo poza repo

- `~/.zsh_history`, baza atuin, klucze SSH, tokeny `gh` — prywatne, przenieś ręcznie.
- `~/.config/zsh/local.zsh` — miejsce na nadpisania per maszyna (ładowane, jeśli istnieje).
- Na źródłowym Macu `.zshenv` źródłuje `~/.cargo/env` bez warunku; wersja w repo robi to
  tylko, gdy plik istnieje, żeby świeży Mac nie wypisywał błędu.
