#!/bin/bash
set -e

terraform state rm yandex_resourcemanager_folder_iam_binding.editor
terraform state rm yandex_resourcemanager_folder_iam_binding.images-puller
terraform destroy -auto-approve