# Kubernetes and container workflow.

alias k='kubectl'
alias kctx='kubectx'
alias kns='kubens'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias klf='kubectl logs --follow'
alias kaf='kubectl apply --filename'

kswitchns() {
  if (( $# == 0 )); then
    kubectl config view --minify --output 'jsonpath={..namespace}'
    print
  else
    kubectl config set-context --current --namespace="$1"
  fi
}

kgpan() {
  kubectl get pods --all-namespaces "$@"
}

kshell() {
  (( $# >= 1 )) || { print -u2 -- 'usage: kshell <pod> [command ...]'; return 2; }
  local pod="$1"
  shift
  if (( $# == 0 )); then
    kubectl exec -it "$pod" -- /bin/bash
  else
    kubectl exec -it "$pod" -- "$@"
  fi
}

kportforward() {
  (( $# >= 2 )) || {
    print -u2 -- 'usage: kportforward <pod> <local-port:remote-port> [options]'
    return 2
  }
  kubectl port-forward "$@"
}
alias kpfw='kportforward'

if (( $+commands[stern] )); then
  alias klogs='stern'
  alias klogsall='stern --all-namespaces'
fi

if (( $+commands[k9s] )); then
  alias k9='k9s'
fi

if (( $+commands[ctop] )); then
  alias ct='ctop'
fi

if (( $+commands[lazydocker] )); then
  alias lzd='lazydocker'
fi
