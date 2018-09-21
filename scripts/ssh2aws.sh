#!/bin/bash

[[ -z $1 ]] && id=i-0e7c93f0d3b065b89 || id=$1
pip=`aws ec2 describe-instances --instance-ids $id --query "Reservations[*].Instances[*].PublicIpAddress"`
echo "Connecting to public ip address ${pip}"
/usr/bin/ssh ec2-user@${pip}
