The aws-node-termination-handler (NTH) can operate in two different modes: Instance Metadata Service (IMDS) or the Queue Processor.

The aws-node-termination-handler Instance Metadata Service Monitor will run a small pod on each host to perform monitoring of IMDS paths like /spot or /events and react accordingly to drain and/or cordon the corresponding node.

The aws-node-termination-handler Queue Processor will monitor an SQS queue of events from Amazon EventBridge for ASG lifecycle events, EC2 status change events, Spot Interruption Termination Notice events, and Spot Rebalance Recommendation events. When NTH detects an instance is going down, we use the Kubernetes API to cordon the node to ensure no new work is scheduled there, then drain it, removing any existing work. The termination handler Queue Processor requires AWS IAM permissions to monitor and manage the SQS queue and to query the EC2 API.

In this section, we will use Queue Processor, and you can use the following link to see the detail.

https://github.com/aws/aws-node-termination-handler#installation-and-configuration-1

## 1. Create SQS (about 5 mins)
* Create SQS.
```bash
. ~/environment/eksworkshopguide/eks-spot-node-interruption-handler-1-sqs.sh
```

## 2.Setup EventBridge
*Run the command.
```bash
. ~/environment/eksworkshopguide/eks-spot-node-interruption-handler-2-eventbridge.sh
```
## 3.Install NTH
*Run the command.
```bash
. ~/environment/eksworkshopguide/eks-spot-node-interruption-handler-3-nth.sh
```
