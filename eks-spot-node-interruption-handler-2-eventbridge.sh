#!/bin/bash
#AWS Node Termination Handler on EKS - Using Queue Processor (requires AWS IAM Permissions)
## Create EKS workshop spot termination rule.
aws events put-rule \
  --name EksWorkshopASGTermRule \
  --event-pattern "{\"source\":[\"aws.autoscaling\"],\"detail-type\":[\"EC2 Instance-terminate Lifecycle Action\"]}"

aws events put-targets --rule EksWorkshopASGTermRule \
  --targets "Id"="1","Arn"="arn:aws:sqs:${AWS_REGION}:${ACCOUNT_ID}:${SQS_QUEUE_NAME}"

aws events put-rule \
  --name EksWorkshopSpotTermRule \
  --event-pattern "{\"source\": [\"aws.ec2\"],\"detail-type\": [\"EC2 Spot Instance Interruption Warning\"]}"

aws events put-targets --rule EksWorkshopSpotTermRule \
  --targets "Id"="1","Arn"="arn:aws:sqs:${AWS_REGION}:${ACCOUNT_ID}:${SQS_QUEUE_NAME}"

aws events put-rule \
  --name EksWorkshopRebalanceRule \
  --event-pattern "{\"source\": [\"aws.ec2\"],\"detail-type\": [\"EC2 Instance Rebalance Recommendation\"]}"

aws events put-targets --rule EksWorkshopRebalanceRule \
  --targets "Id"="1","Arn"="arn:aws:sqs:${AWS_REGION}:${ACCOUNT_ID}:${SQS_QUEUE_NAME}"

aws events put-rule \
  --name EksWorkshopInstanceStateChangeRule \
  --event-pattern "{\"source\": [\"aws.ec2\"],\"detail-type\": [\"EC2 Instance State-change Notification\"]}"

aws events put-targets --rule EksWorkshopInstanceStateChangeRule \
  --targets "Id"="1","Arn"="arn:aws:sqs:${AWS_REGION}:${ACCOUNT_ID}:${SQS_QUEUE_NAME}"

aws events put-rule \
  --name EksWorkshopScheduledChangeRule \
  --event-pattern "{\"source\": [\"aws.health\"],\"detail-type\": [\"AWS Health Event\"],\"detail\": {\"service\": [\"EC2\"],\"eventTypeCategory\": [\"scheduledChange\"]}}"

aws events put-targets --rule EksWorkshopScheduledChangeRule \
  --targets "Id"="1","Arn"="arn:aws:sqs:${AWS_REGION}:${ACCOUNT_ID}:${SQS_QUEUE_NAME}"
