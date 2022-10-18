#!/bin/bash
#AWS Node Termination Handler on EKS - Using IMDS
sed 's/$AWS_REGION/'"${AWS_REGION}"'/g' eksworkshopguide/yamls/ekscluster-unamanged-nodegroup-spot-template.yaml > eksworkshopguide/yamls/ekscluster-unamanged-nodegroup-spot.yaml

# create a nodegroup with spot.
eksctl create nodegroup -f eksworkshopguide/yamls/ekscluster-unamanged-nodegroup-spot.yaml

#install node interruption handler (IMDS)
kubectl apply -f https://github.com/aws/aws-node-termination-handler/releases/download/v1.17.3/all-resources.yaml

#create fis policy and role.
read -r -d '' fis_role_trust_policy <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                  "fis.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
echo "${fis_role_trust_policy}" > fis-role-trust-policy.json

read -r -d '' fis_role_permissions_policy <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFISExperimentRoleEC2Actions",
            "Effect": "Allow",
            "Action": [
                "ec2:RebootInstances",
                "ec2:StopInstances",
                "ec2:StartInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*"
        },
        {
            "Sid": "AllowFISExperimentRoleSpotInstanceActions",
            "Effect": "Allow",
            "Action": [
                "ec2:SendSpotInstanceInterruptions"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*"
        }
    ]
}
EOF
echo "${fis_role_permissions_policy}" > fis-role-permissions-policy.json

#create fis role, and attach policy.
aws iam create-role --role-name eksworkshop-fis-role --assume-role-policy-document file://fis-role-trust-policy.json
aws iam put-role-policy --role-name eksworkshop-fis-role --policy-name my-fis-policy --policy-document file://fis-role-permissions-policy.json

