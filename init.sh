#!/bin/bash
set -e

cd ansible
ansible-galaxy collection install -r requirements.yml
cd ../terraform/init
#terraform init
terraform apply -auto-approve
cd ../../ansible
sleep 30
ansible-playbook playbooks/init_k8s.yml
