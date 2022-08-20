#!/bin/bash
set -e

cd terraform/managed
terraform init
terraform apply -auto-approve
