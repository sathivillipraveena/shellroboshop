#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0cdb841294c052660"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z096607625SAROAU2N8QT"
DOMAIN_NAME="roboticgear.shop"

for instance in $@
do
    echo "Creating instance: $instance"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    if [ -z "$INSTANCE_ID" ]; then
        echo "ERROR: Failed to create instance for $instance. Skipping..."
        continue
    fi

    echo "Instance ID: $INSTANCE_ID"

    if [ "$instance" != "frontend" ]
    then
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
    fi

    if [ -z "$IP" ]; then
        echo "ERROR: Could not fetch IP for $instance. Skipping Route53 update..."
        continue
    fi

    RECORD_NAME="$instance.$DOMAIN_NAME"
    echo "$instance IP address: $IP"

    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '{
            "Comment": "Creating or Updating a record set for '$instance'",
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$RECORD_NAME'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{
                        "Value": "'$IP'"
                    }]
                }
            }]
        }'

    echo "$instance setup complete."
    echo "-----------------------------------"
done