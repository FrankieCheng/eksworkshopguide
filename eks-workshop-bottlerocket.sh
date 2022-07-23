#!/bin/bash
#bottlerocket

#replace the parameter for nodegroup template.
sed 's/$AWS_REGION/'"${AWS_REGION}"'/g' eksworkshopguide/yamls/ekscluster-nodegroup-bottlerocket-template.yaml > eksworkshopguide/yamls/ekscluster-nodegroup-bottlerocket.yaml

# create bottlerocket nodegroup.
eksctl create nodegroup --config-file eksworkshopguide/yamls/ekscluster-nodegroup-bottlerocket.yaml

# check bottlerocket nodegroup status.
eksctl get nodegroups --cluster eksworkshop-eksctl

# create bottlerocket node status.
kubectl get nodes --label-columns=bottlerocket,alpha.eksctl.io/nodegroup-name