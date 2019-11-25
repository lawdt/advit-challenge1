#!/bin/bash

# getting instance region
instance_region=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
instance_region=$(echo $instance_region| sed 's/.$//')

# getting instance id
instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)

# get instance tag Project
instance_project=$(aws ec2 describe-tags --region $instance_region --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=Project" --query "Tags[*].Value" --output text)
if [ ! -n "$instance_project" ]
then exit
fi

# getting allocation id
eip_id=$(aws ec2 describe-addresses --region $instance_region --filters "Name=tag:Project,Values=$instance_project" --query "Addresses[?AssociationId==null].AllocationId" --output text)
if [ ! -n "$eip_id" ]
then exit
fi

# attach eip
aws ec2 associate-address --region $instance_region --instance-id $instance_id --allocation-id $eip_id --no-allow-reassociation