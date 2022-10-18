#!/bin/bash
#AWS Node Termination Handler on EKS - Using Queue Processor (requires AWS IAM Permissions)
## install nth.
#sed 's/$AWS_REGION/'"${AWS_REGION}"'/g;s/$ACCOUNT_ID/'"${ACCOUNT_ID}"'/g;s/$SQS_QUEUE_NAME/'"${SQS_QUEUE_NAME}"'/g;' eksworkshopguide/yamls/all-resources-queue-processor-template.yaml > eksworkshopguide/yamls/all-resources-queue-processor.yaml
#kubectl apply -f eksworkshopguide/yamls/all-resources-queue-processor.yaml
read -r -d '' aws_node_termination_handler_policy <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeTags",
                "ec2:DescribeInstances",
                "sqs:DeleteMessage",
                "sqs:ReceiveMessage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
echo "${aws_node_termination_handler_policy}" > aws_node_termination_handler_policy.json

AWS_NODE_TERMINATION_POLICY_NAME="aws-node-termination-handler-policy"
#
# Create an IAM permission policy to be associated with the role, if the policy does not already exist
#
SERVICE_ACCOUNT_IAM_POLICY_ID=$(aws iam get-policy --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${AWS_NODE_TERMINATION_POLICY_NAME}" --query 'Policy.PolicyId' --output text)
if [ "$SERVICE_ACCOUNT_IAM_POLICY_ID" = "" ]; 
then
  echo "Creating a new permission policy $AWS_NODE_TERMINATION_POLICY_NAME"
  aws iam create-policy --policy-name $AWS_NODE_TERMINATION_POLICY_NAME --policy-document file://aws_node_termination_handler_policy.json 
else
  echo "Permission policy $AWS_NODE_TERMINATION_POLICY_NAME already exists"
fi

eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" --name aws-node-termination-handler --namespace kube-system \
  --role-name "${CLUSTER_NAME}-aws-node-termination-handler" \
  --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${AWS_NODE_TERMINATION_POLICY_NAME}" \
  --approve

helm upgrade --install aws-node-termination-handler \
  --namespace kube-system \
  --set enableSqsTerminationDraining=true \
  --set queueURL=https://sqs.${AWS_REGION}.amazonaws.com/${ACCOUNT_ID}/${SQS_QUEUE_NAME} \
  eks/aws-node-termination-handler

kubectl annotate serviceaccount -n kube-system aws-node-termination-handler eks.amazonaws.com/role-arn=arn:aws:iam::${ACCOUNT_ID}?:role/eksworkshop-eksctl-aws-node-termination-handler