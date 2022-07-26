#!/bin/bash
##setup helm.
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


#init karpenter related env.
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name eksworkshop-eksctl --query "cluster.endpoint" --output text)"
export KARPENTER_VERSION=v0.13.2
export CLUSTER_NAME=eksworkshop-eksctl
echo "export CLUSTER_ENDPOINT=${CLUSTER_ENDPOINT}" | tee -a ~/.bash_profile
echo "export KARPENTER_VERSION=${KARPENTER_VERSION}" | tee -a ~/.bash_profile
echo "export CLUSTER_NAME=${CLUSTER_NAME}" | tee -a ~/.bash_profile
source  ~/.bash_profile

echo $KARPENTER_VERSION $CLUSTER_NAME $AWS_REGION $ACCOUNT_ID

TEMPOUT=$(mktemp)

#use cloudformation to setup karpenter
curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

#create iam identity mapping for system node
eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster "${CLUSTER_NAME}" \
  --arn "arn:aws:iam::${ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
  --group system:bootstrappers \
  --group system:nodes
#create AWS IAM Roles mapping to Kubernetes Service Accounts. for karpenter
eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
  --role-name "${CLUSTER_NAME}-karpenter" \
  --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
  --role-only \
  --approve

#export karpenter iam role.
export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"

#create service linked role for spot service.
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com || true
# If the role has already been successfully created, you will see:
# An error occurred (InvalidInput) when calling the CreateServiceLinkedRole operation: Service role name AWSServiceRoleForEC2Spot has been taken in this account, please try a different suffix.

#add karpenter to helm
helm repo add karpenter https://charts.karpenter.sh/
helm repo update

#install
helm upgrade --install --namespace karpenter --create-namespace \
  karpenter karpenter/karpenter \
  --version ${KARPENTER_VERSION} \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set clusterName=${CLUSTER_NAME} \
  --set clusterEndpoint=${CLUSTER_ENDPOINT} \
  --set aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME} \
  --wait # for the defaulting webhook to install before creating a Provisioner

#setup karpenter provisioner.
kubectl apply -f eksworkshopguide/yamls/karpenter-provisioner.yaml
