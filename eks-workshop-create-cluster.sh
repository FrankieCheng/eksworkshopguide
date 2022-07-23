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

#check the iam role is valid or not.
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

#add the bash completion on eksctl.
eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

# replace parameters.
sed 's/$AWS_REGION/'"${AWS_REGION}"'/g;s/$AZ0/'"${AZS[0]}"'/g;s/$AZ1/'"${AZS[1]}"'/g;s/$AZ2/'"${AZS[2]}"'/g' eksworkshopguide/yamls/ekscluster-template.yaml > eksworkshopguide/yamls/ekscluster.yaml

# create cluster.
eksctl create cluster -f eksworkshopguide/yamls/ekscluster.yaml

#replace the parameter for nodegroup template.
sed 's/$AWS_REGION/'"${AWS_REGION}"'/g' eksworkshopguide/yamls/ekscluster-nodegroup-template.yaml > eksworkshopguide/yamls/ekscluster-nodegroup.yaml

# create nodegroup.
eksctl create nodegroup --config-file eksworkshopguide/yamls/ekscluster-nodegroup.yaml

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

#create the iam identity mapping, the iam user can access the eks cluster on console.
eksctl create iamidentitymapping --cluster eksworkshop-eksctl --arn ${rolearn} --group system:masters --username admin

#show the configmap.
kubectl describe configmap -n kube-system aws-auth
