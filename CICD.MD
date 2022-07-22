1. Create Multi-Arch Docker file (about 20 mins)
```bash
. ~/environment/eksworkshopguide/eks-graviton2-cicd.sh
```
* Clone the Repo from Graviton workshop
* Create the CodePipeline.
* Commit the code to trigger Codepipeline.
* Monitor CodePipeline steps using AWS Console by opening this link in a new tab. https://ap-southeast-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/graviton2-pipeline-lab/view?region=ap-southeast-1
* Wait all steps of CodePipeline are successful
