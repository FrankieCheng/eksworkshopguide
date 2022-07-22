#!/bin/bash
#ec2 iam change
export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 associate-iam-instance-profile --instance-id $instance_id --iam-instance-profile Name=eksworkshop-admin

#update cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

#install jq.....
sudo yum -y install jq gettext bash-completion moreutils

echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc

#install kubectl
sudo curl --silent --location -o /usr/local/bin/kubectl \
	   https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl

sudo chmod +x /usr/local/bin/kubectl

kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

#set the AWS Load Balancer Controller version 
echo 'export LBC_VERSION="v2.4.1"' >>  ~/.bash_profile
echo 'export LBC_CHART_VERSION="1.4.1"' >>  ~/.bash_profile
source  ~/.bash_profile

#update-environment
aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))

test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export AZS=(${AZS[@]})" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

aws sts get-caller-identity --query Arn | grep eksworkshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"

#create custom kms.
#aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)

#export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)
#echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bash_profile

source  ~/.bash_profile

#install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

sudo mv -v /tmp/eksctl /usr/local/bin

eksctl version

eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

# replace parameters.
sed 's/$AWS_REGION/'"${AWS_REGION}"'/g;s/$AZ0/'"${AZS[0]}"'/g;s/$AZ1/'"${AZS[1]}"'/g;s/$AZ2/'"${AZS[2]}"'/g' eksworkshopguide/yamls/ekscluster-template.yaml > eksworkshopguide/yamls/ekscluster.yaml

# create cluster.
eksctl create cluster -f eksworkshopguide/yamls/ekscluster.yaml

kubectl get nodes # if we see our 3 nodes, we know we have authenticated correctly

aws eks update-kubeconfig --name eksworkshop-eksctl --region ${AWS_REGION}

STACK_NAME=$(eksctl get nodegroup --cluster eksworkshop-eksctl -o json | jq -r '.[].StackName')
ROLE_NAME=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME | jq -r '.StackResources[] | select(.ResourceType=="AWS::IAM::Role") | .PhysicalResourceId')
echo "export ROLE_NAME=${ROLE_NAME}" | tee -a ~/.bash_profile

#EKS Console credentials to your new cluster
c9builder=$(aws cloud9 describe-environment-memberships --environment-id=$C9_PID | jq -r '.memberships[].userArn')
if echo ${c9builder} | grep -q user; then
	rolearn=${c9builder}
        echo Role ARN: ${rolearn}
elif echo ${c9builder} | grep -q assumed-role; then
        assumedrolename=$(echo ${c9builder} | awk -F/ '{print $(NF-1)}')
        rolearn=$(aws iam get-role --role-name ${assumedrolename} --query Role.Arn --output text) 
        echo Role ARN: ${rolearn}
fi

eksctl create iamidentitymapping --cluster eksworkshop-eksctl --arn ${rolearn} --group system:masters --username admin

kubectl describe configmap -n kube-system aws-auth


##setup helm.
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

helm version --short

helm repo add stable https://charts.helm.sh/stable

helm search repo stable

helm completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
source <(helm completion bash)


#setup karpenter.
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name eksworkshop-eksctl --query "cluster.endpoint" --output text)"

export KARPENTER_VERSION=v0.13.2

export CLUSTER_NAME=eksworkshop-eksctl

echo "export CLUSTER_ENDPOINT=${CLUSTER_ENDPOINT}" | tee -a ~/.bash_profile
echo "export KARPENTER_VERSION=${KARPENTER_VERSION}" | tee -a ~/.bash_profile
echo "export CLUSTER_NAME=${CLUSTER_NAME}" | tee -a ~/.bash_profile

source  ~/.bash_profile

echo $KARPENTER_VERSION $CLUSTER_NAME $AWS_REGION $ACCOUNT_ID

TEMPOUT=$(mktemp)

curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster "${CLUSTER_NAME}" \
  --arn "arn:aws:iam::${ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
  --group system:bootstrappers \
  --group system:nodes

eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
  --role-name "${CLUSTER_NAME}-karpenter" \
  --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
  --role-only \
  --approve

export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"

aws iam create-service-linked-role --aws-service-name spot.amazonaws.com || true
# If the role has already been successfully created, you will see:
# An error occurred (InvalidInput) when calling the CreateServiceLinkedRole operation: Service role name AWSServiceRoleForEC2Spot has been taken in this account, please try a different suffix.

helm repo add karpenter https://charts.karpenter.sh/
helm repo update

helm upgrade --install --namespace karpenter --create-namespace \
  karpenter karpenter/karpenter \
  --version ${KARPENTER_VERSION} \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set clusterName=${CLUSTER_NAME} \
  --set clusterEndpoint=${CLUSTER_ENDPOINT} \
  --set aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME} \
  --wait # for the defaulting webhook to install before creating a Provisioner

SUBNET_IDS=$(aws cloudformation describe-stacks \
    --stack-name eksctl-${CLUSTER_NAME}-cluster \
    --query 'Stacks[].Outputs[?OutputKey==`SubnetsPrivate`].OutputValue' \
    --output text)
aws ec2 create-tags \
    --resources $(echo $SUBNET_IDS | tr ',' '\n') \
    --tags Key="karpenter.sh/discovery",Value=${CLUSTER_NAME}

VALIDATION_SUBNETS_IDS=$(aws ec2 describe-subnets --filters Name=tag:"karpenter.sh/discovery",Values= --query "Subnets[].SubnetId" --output text | sed 's/\t/,/')
echo "$SUBNET_IDS == $VALIDATION_SUBNETS_IDS"


SG_IDS=$(aws cloudformation describe-stacks \
    --stack-name eksctl-${CLUSTER_NAME}-cluster \
    --query 'Stacks[].Outputs[?OutputKey==`SecurityGroup`].OutputValue' \
    --output text)
aws ec2 create-tags \
    --resources $(echo $SG_IDS | tr ',' '\n') \
    --tags Key="karpenter.sh/discovery",Value=${CLUSTER_NAME}

VALIDATION_SG_IDS=$(aws ec2 describe-security-groups --filters Name=tag:"karpenter.sh/discovery",Values= --query "SecurityGroups[].GroupId" --output text | sed 's/\t/,/')
echo "$SG_IDS == $VALIDATION_SG_IDS"

kubectl apply -f eksworkshopguide/yamls/karpenter-provisioner.yaml



