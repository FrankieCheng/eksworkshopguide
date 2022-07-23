#!/bin/bash
#CICD
#clone the graviton workshop.
git clone https://github.com/aws-samples/graviton2-workshop 
#upgrade awscli.
sudo pip install --upgrade awscli && hash -r

cd graviton2-workshop

#add the disk volumn size since the space is not enough.
./scripts/resize.sh

#install aws cdk
nvm install 14
npm install -g aws-cdk@1.108.0
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade aws-cdk.core==1.108.0 
pip install -r requirements.txt

#run the cdk to deploy cloudformation.
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

#check the node arch.
kubectl get nodes --label-columns=kubernetes.io/arch