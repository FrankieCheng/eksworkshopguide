#!/bin/bash
#Graviton
eksctl utils update-coredns --cluster eksworkshop-eksctl 
eksctl utils update-kube-proxy --cluster eksworkshop-eksctl --approve
eksctl utils update-aws-node --cluster eksworkshop-eksctl --approve
eksctl create nodegroup   --cluster eksworkshop-eksctl   --region $AWS_REGION   --name eksworkshop-eksctl-ng-graviton2   --node-type m6g.large   --nodes 1  --nodes-min 1  --nodes-max 3  --managed
#check the node arch.
kubectl get nodes --label-columns=kubernetes.io/arch