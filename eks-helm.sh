#!/bin/bash
##install helm
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

#helm init.
helm version --short
helm repo add stable https://charts.helm.sh/stable
helm search repo stable

#helm bash completion.
helm completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
source <(helm completion bash)
