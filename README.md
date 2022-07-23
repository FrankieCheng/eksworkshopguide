# eksworkshopguide
# 1.Following the guide [Init](Init.MD) to setup the EKS cluster and karpenter. 
* Create a role
* Install Kubectl, helm
* Create a cluster
* Install Karpenter
 
# 2.Following the guide [CICD](CICD.MD) to generate the multi-arch images on X86 and arm64 (Graviton)
* clone a repo from git
* use cicd to init CodePipeline, CodeBuild, CodeCommit
* create ecr repository to store the multi-arch images.
* commit the code to codecommit to trigger CodePipeline to generate the multiarch images.

# 3.Use [Graviton](Graviton.MD) the test application to deploy workload with multi arch.
* create a graviton nodegroup.
* deploy the multiarch image on x86 and graviton nodegroup.
