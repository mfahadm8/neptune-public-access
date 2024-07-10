#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Custom error handler
function error_exit {
    echo "$1" 1>&2
    exit 1
}

# Check if the required argument is provided
if [ "$#" -ne 1 ]; then
    error_exit "Usage: $0 <neptune-cluster-name>"
fi

NEPTUNE_CLUSTER_NAME=$1
DOMAIN_NAME=$2 | "powerodd.com"
NEPTUNE_SUB_DOMAIN=$3 | "neptune-db.powerodd.com"

# Step 1: Retrieve the VPC ID of the Neptune cluster
NEPTUNE_CLUSTER_INFO=$(aws neptune describe-db-clusters --db-cluster-identifier $NEPTUNE_CLUSTER_NAME) || error_exit "Failed to retrieve Neptune cluster info"
INSTANCE_ID=$(echo $NEPTUNE_CLUSTER_INFO | perl -nle 'print $& if m{"DBInstanceIdentifier": "\K[^"]+}' | head -n 1) || error_exit "Failed to extract DBInstanceIdentifier"
VPC_ID=$(aws neptune describe-db-instances --db-instance-identifier $INSTANCE_ID | perl -nle 'print $& if m{"VpcId": "\K[^"]+}') || error_exit "Failed to retrieve VPC ID"

echo "Retrieved VPC ID: $VPC_ID"

# Step 2: Retrieve public subnet IDs within the VPC
SUBNET_IDS=($(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=true" --query "Subnets[*].SubnetId" --output text))
if [ ${#SUBNET_IDS[@]} -lt 2 ]; then
    error_exit "Less than two public subnets found in the VPC"
fi

echo "Retrieved Public Subnet IDs: ${SUBNET_IDS[@]}"

# Step 3: Retrieve private IPs of the Neptune cluster
INSTANCE_IDS=$(echo $NEPTUNE_CLUSTER_INFO | perl -nle 'print $& if m{"DBInstanceIdentifier": "\K[^"]+}') || error_exit "Failed to extract DBInstanceIdentifiers"
PRIVATE_IPS=()
for INSTANCE_ID in $INSTANCE_IDS; do
    ENDPOINT=$(aws neptune describe-db-instances --db-instance-identifier $INSTANCE_ID | perl -nle 'print $& if m{"Address": "\K[^"]+}') || error_exit "Failed to retrieve private IP"
    echo "Retrieved endpoint $ENDPOINT"
    RESOLVED_IP=$(dig +short $ENDPOINT)
    PRIVATE_IPS+=($RESOLVED_IP)
done

echo "Retrieved Neptune cluster IPs: ${PRIVATE_IPS[@]}"

# Step 4: Retrieve the hosted zone ID for the domain
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name $DOMAIN_NAME --query "HostedZones[0].Id" --output text | cut -d'/' -f3) || error_exit "Failed to retrieve Hosted Zone ID"

if [ -z "$HOSTED_ZONE_ID" ]; then
    error_exit "Hosted Zone ID not found for domain $DOMAIN_NAME"
fi

echo "Retrieved Hosted Zone ID: $HOSTED_ZONE_ID"

# Step 5: Retrieve the certificate ARN for the domain
CERT_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME'].CertificateArn | [0]" --output text) || error_exit "Failed to retrieve certificate ARN"

if [ "$CERT_ARN" == "None" ]; then
    error_exit "Certificate ARN not found for domain $DOMAIN_NAME"
fi

echo "Retrieved Certificate ARN: $CERT_ARN"

# Step 7: Create a new Application Load Balancer using CloudFormation template
STACK_NAME="NeptuneALBStack"

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file alb-template.yaml \
    --parameter-overrides SubnetIds="${SUBNET_IDS[0]},${SUBNET_IDS[1]}" VpcId="$VPC_ID" CertArn="$CERT_ARN" TargetIP="${PRIVATE_IPS[0]}" HostedZoneId="$HOSTED_ZONE_ID" NeptuneSubDomain="$NEPTUNE_SUB_DOMAIN"\
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset || error_exit "Failed to deploy CloudFormation stack"

echo "CloudFormation stack creation initiated for ALB"
