#!/bin/bash
#CICD
git clone https://github.com/aws-samples/graviton2-workshop 
sudo pip install --upgrade awscli && hash -r
cd graviton2-workshop

./scripts/resize.sh
nvm install 14
npm install -g aws-cdk@1.108.0
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade aws-cdk.core==1.108.0 
pip install -r requirements.txt
cdk bootstrap aws://$ACCOUNT_ID/$AWS_REGION 
cdk synth 
cdk ls 
cdk deploy --require-approval never GravitonID-pipeline
cd ~/environment/graviton2-workshop/
git clone `aws cloudformation describe-stacks --stack-name GravitonID-pipeline --query "Stacks[0].Outputs[0].OutputValue" --output text`               
cp -r graviton2/cs_graviton/app/* graviton2-pipeline-lab/
cd graviton2-pipeline-lab
git add .
git commit -m "First commit Node.js sample application."
git push

kubectl get nodes --label-columns=kubernetes.io/arch
