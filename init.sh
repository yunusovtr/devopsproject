#!/bin/bash
set -e

cd ansible
ansible-galaxy collection install -r requirements.yml
cd ../terraform/init
terraform apply -auto-approve
cd ../../ansible
ansible-playbook playbooks/init_management_cluster.yml
