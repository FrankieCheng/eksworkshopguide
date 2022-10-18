#!/bin/bash
#AWS Node Termination Handler on EKS - Using Queue Processor (requires AWS IAM Permissions)
## Queue Policy
SQS_QUEUE_NAME="eksworkshop-nth-queue"
QUEUE_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Id": "MyQueuePolicy",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Service": ["events.amazonaws.com", "sqs.amazonaws.com"]
        },
        "Action": "sqs:SendMessage",
        "Resource": [
            "arn:aws:sqs:${AWS_REGION}:${ACCOUNT_ID}:${SQS_QUEUE_NAME}"
        ]
    }]
}
EOF
)

## make sure the queue policy is valid JSON
echo "$QUEUE_POLICY" | jq .

## Save queue attributes to a temp file
cat << EOF > /tmp/queue-attributes.json
{
  "MessageRetentionPeriod": "300",
  "Policy": "$(echo $QUEUE_POLICY | sed 's/\"/\\"/g' | tr -d -s '\n' " ")"
}
EOF

aws sqs create-queue --queue-name "${SQS_QUEUE_NAME}" --attributes file:///tmp/queue-attributes.json

