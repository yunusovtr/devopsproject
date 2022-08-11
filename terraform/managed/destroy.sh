#!/bin/bash
set -e

#kubectl get pvc -o json | jq -r '.items[0] | .metadata.name ' | xargs -n1 kubectl delete pvc
#kubectl get pvc -o json -n app | jq -r '.items[0] | .metadata.name ' | xargs -n1 kubectl delete pvc -n app
terraform state rm yandex_resourcemanager_folder_iam_binding.editor
terraform state rm yandex_resourcemanager_folder_iam_binding.images-puller
terraform destroy -auto-approve