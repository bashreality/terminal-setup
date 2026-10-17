# Security and network helpers. Potentially destructive operations stay explicit.

if (( $+commands[age] )); then
  alias encrypt='age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p'
  alias decrypt='age --decrypt'
fi

if (( $+commands[sops] )); then
  typeset sops_age_key="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
  [[ -r $sops_age_key ]] && export SOPS_AGE_KEY_FILE="$sops_age_key"
  alias sopsd='sops --decrypt'
  alias sopse='sops --encrypt'
  unset sops_age_key
fi

if (( $+commands[bandwhich] )); then
  alias bw='sudo bandwhich'
fi

if (( $+commands[termshark] )); then
  alias shark='sudo termshark'
  alias sniff='sudo termshark -i'
fi

if (( $+commands[nuclei] )); then
  alias nuc='nuclei'
  alias nucupdate='nuclei -update-templates'
fi

if (( $+commands[gobuster] )); then
  alias gbdir='gobuster dir'
  alias gbdns='gobuster dns'
fi

if (( $+commands[amass] )); then
  alias aenum='amass enum -d'
  alias apassive='amass enum -passive -d'
fi

if (( $+commands[httpx] )); then
  alias probe='httpx -silent'
fi

if (( $+commands[searchsploit] )); then
  alias sploit='searchsploit'
fi

ports() {
  if (( $+commands[lsof] )); then
    sudo lsof -nP -iTCP -sTCP:LISTEN
  else
    command netstat -an | command grep LISTEN
  fi
}

myip() {
  command curl --fail --silent --show-error https://whatismyip.akamai.com/
  print
}

nmap-discover() {
  (( $# == 1 )) || { print -u2 -- 'usage: nmap-discover <network>'; return 2; }
  nmap -sn -- "$1"
}

scan-ports() {
  (( $# == 1 )) || { print -u2 -- 'usage: scan-ports <target>'; return 2; }
  sudo nmap -sS -sV -O -- "$1"
}

vuln-scan() {
  (( $# == 1 )) || { print -u2 -- 'usage: vuln-scan <target>'; return 2; }
  nmap --script vuln -- "$1"
}

portscan() {
  (( $# == 1 )) || { print -u2 -- 'usage: portscan <target>'; return 2; }
  if (( $+commands[rustscan] )); then
    rustscan -a "$1" -- -sV -sC
  else
    nmap -sV -sC -- "$1"
  fi
}

recon() {
  (( $# == 1 )) || { print -u2 -- 'usage: recon <domain>'; return 2; }
  (( $+commands[subfinder] && $+commands[httpx] )) || {
    print -u2 -- 'recon requires subfinder and httpx'
    return 1
  }

  local domain="$1"
  local outdir="recon_${domain}_$(date +%Y%m%d_%H%M%S)"
  command mkdir -p -- "$outdir" || return
  subfinder -d "$domain" -o "$outdir/subdomains.txt" -silent || return
  httpx -l "$outdir/subdomains.txt" -o "$outdir/live.txt" -silent || return
  print -- "Saved results in $outdir/"

  if (( $+commands[nuclei] )); then
    nuclei -l "$outdir/live.txt" -o "$outdir/vulns.txt" -silent
  fi
}

fuzz() {
  (( $# == 1 )) || { print -u2 -- 'usage: fuzz <url>'; return 2; }
  (( $+commands[ffuf] )) || { print -u2 -- 'fuzz requires ffuf'; return 1; }

  local wordlist
  for wordlist in \
    /opt/homebrew/share/wordlists/dirb/common.txt \
    /usr/share/wordlists/dirb/common.txt \
    "$HOME/.local/share/wordlists/common.txt"; do
    [[ -r $wordlist ]] && break
  done
  [[ -r $wordlist ]] || { print -u2 -- 'fuzz: no common wordlist found'; return 1; }

  ffuf -w "$wordlist" -u "${1%/}/FUZZ" -mc 200,301,302,403 -c
}

netstat-summary() {
  print -- 'Listening sockets:'
  command netstat -an | command grep -c LISTEN
  print -- 'Established connections:'
  command netstat -an | command grep -c ESTABLISHED
}

analyze-failed-logins() {
  if [[ $OSTYPE == darwin* ]]; then
    /usr/bin/log show --style syslog \
      --predicate 'eventMessage CONTAINS[c] "Failed password"' \
      --last 24h | command tail -20
  else
    sudo grep 'Failed password' /var/log/auth.log | command tail -20
  fi
}

sysinfo() {
  print -- "Host: $(hostname)"
  print -- "OS: $(sw_vers -productName) $(sw_vers -productVersion)"
  print -- "Kernel: $(uname -sr)"
  print -- "Uptime: $(uptime)"
  print -- "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
}
