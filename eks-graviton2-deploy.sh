#!/bin/bash
#deploy multi arch.
#set env.
export ECR_REPO_URI=$(aws ecr describe-repositories --repository-name graviton2-pipeline-lab  | jq -r '.repositories[0].repositoryUri')
export MULTI_IMAGE_TAG=$(aws ecr describe-images --repository-name graviton2-pipeline-lab --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' | jq -r .)
export CONTAINER_URI=$ECR_REPO_URI:$MULTI_IMAGE_TAG
echo $ECR_REPO_URI
echo $MULTI_IMAGE_TAG
echo $CONTAINER_URI
#use ssm parameter store to save container uri.
aws ssm put-parameter --name "graviton_lab_container_uri" --value $CONTAINER_URI --type String --overwrite 
CONTAINER_URI=`aws ssm get-parameter --name "graviton_lab_container_uri" | jq -r .Parameter.Value`
echo $CONTAINER_URI

#check the node arch.
kubectl get nodes --label-columns=kubernetes.io/arch
#replace parameters
sed "s#{{container_uri}}#$CONTAINER_URI#" ~/environment/eksworkshopguide/yamls/multi-arch-template.yaml > ~/environment/eksworkshopguide/yamls/multi-arch.yaml

#deploy the multi arch application.
kubectl apply -f ~/environment/eksworkshopguide/yamls/multi-arch.yaml

#check the pods status.
kubectl get pods -o wide 