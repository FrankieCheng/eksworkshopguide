# eksworkshopguide
## 1.Following the guide [Init](Init.MD) to setup the EKS cluster. ---(Time: about 25 mins)
* Create a role
* Install Kubectl
* Create a cluster
## 2.Following the guide [Karpenter](Karpenter.MD) to install helm and Karpenter ---(Time: about 10 mins)
* Install helm
* Setup Karpenter
* Deploy the test application and scale the deployment to check Karpenter status.
 
## 3.Following the guide [CICD](CICD.MD) to generate the multi-arch images on X86 and arm64 (Graviton)  ---(Time: about 20 mins)
* clone a repo from git
* use cicd to init CodePipeline, CodeBuild, CodeCommit
* create ecr repository to store the multi-arch images.
* commit the code to codecommit to trigger CodePipeline to generate the multiarch images.

## 4.Use [Graviton](Graviton.MD) the test application to deploy workload with multi arch.---(Time: about 10 mins)
* create a graviton nodegroup.
* deploy the multiarch image on x86 and graviton nodegroup.


## 5.Use [Bottlerocket](Bottlerocket.MD) to create a bottlerocket nodegroup.---(Time: about 10 mins)
* Create a key pair which can access the bottlerocket node.
* create 2 bottlerocket nodegroups, and one with the SSH.

## 6.Use [EKS ALB ingress](Alb-ingress.MD) to install a ingress controller and deploy the game 2048.---(Time: about 10 mins)
* Install alb ingress controller.
* Deploy the game 2048.

## 7.Use [EKS Node Interruption Handler](Node-Interruption-Handler-IMDS.MD) to setup Node Interruption Handler.---(Time: about 10 mins)
* Setup Environment.
* Deploy Node Interruption Handler.

## Resources
* eksworkshop: https://www.eksworkshop.com/010_introduction/

* Karpenter: https://www.eksworkshop.com/beginner/085_scaling_karpenter/

* IAM最小权限：https://github.com/weaveworks/eksctl/blob/main/userdocs/src/usage/minimum-iam-policies.md

* CodeBuild Multi Arch: https://aws.amazon.com/cn/blogs/devops/creating-multi-architecture-docker-images-to-support-graviton2-using-aws-codebuild-and-aws-codepipeline/

* eksctl examples: https://github.com/weaveworks/eksctl/tree/main/examples

* Node Interruption Handler: https://github.com/aws/aws-node-termination-handler
