#!/bin/bash
app_version=$1
yum install python3.11-devel python3.11-pip -y
pip3.11 install ansible botocore boto3
cd /tmp
ansible-pull -U https://github.com/gollamahesh/Ansible_Roboshop_Roles-tf.git -e component=catalogue -e app_version=$app_version main.yaml