# Cloud and infrastructure workflow.

alias gcl='gcloud'
alias gcpa='gcloud config configurations activate'
alias gcpl='gcloud config configurations list'
alias gcps='gcloud config set project'

gcpswitch() {
  if (( $# == 0 )); then
    print -- "Current project: $(gcloud config get-value project 2>/dev/null)"
    gcloud projects list
  else
    gcloud config set project "$1"
  fi
}

if (( $+commands[helm] )); then
  alias hm='helm'
  alias hmi='helm install'
  alias hmu='helm upgrade'
  alias hml='helm list'
  alias hms='helm search repo'
fi

if (( $+commands[terraform] )); then
  alias tf='terraform'
  alias tfi='terraform init'
  alias tfp='terraform plan'
  alias tfa='terraform apply'
fi
