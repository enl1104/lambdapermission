#!/bin/bash

# Define variables
roleName="LambdaRDSAccessRole"
policyName="LambdaRDSCustomAccessPolicy"
trustPolicyFile="trust-policy.json"
customPolicyFile="rds-access-policy.json"

# Create a trust policy file
cat > ${trustPolicyFile} << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOL

# Create the IAM role
aws iam create-role \
    --role-name ${roleName} \
    --assume-role-policy-document file://${trustPolicyFile}

# Attach the AWS managed policy for CloudWatch Logs access
aws iam attach-role-policy \
    --role-name ${roleName} \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create a custom policy for RDS access
cat > ${customPolicyFile} << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds-db:connect",
        "rds:DescribeDBInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOL

# Create the custom policy and capture the PolicyArn
policyArn=$(aws iam create-policy \
    --policy-name ${policyName} \
    --policy-document file://${customPolicyFile} \
    --query 'Policy.Arn' \
    --output text)

# Attach the custom policy to the role
aws iam attach-role-policy \
    --role-name ${roleName} \
    --policy-arn ${policyArn}

echo "IAM role and policies setup completed."
