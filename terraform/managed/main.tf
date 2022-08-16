resource "yandex_kubernetes_cluster" "k8s-cluster" {
 name = "k8s-cluster"
 network_id = yandex_vpc_network.k8s-network.id
 master {
  public_ip = true
  version = "1.21"
  zonal {
     zone      = yandex_vpc_subnet.k8s-subnet.zone
     subnet_id = yandex_vpc_subnet.k8s-subnet.id
   }
 }
 service_account_id      = yandex_iam_service_account.k8s-account.id
 node_service_account_id = yandex_iam_service_account.k8s-account.id
   depends_on = [
     yandex_resourcemanager_folder_iam_binding.editor,
     yandex_resourcemanager_folder_iam_binding.images-puller
   ]
  # provisioner "local-exec" {
  #   command = "yc managed-kubernetes cluster get-credentials ${self.name} --external --force"
  # }
  # provisioner "local-exec" {
  #   command = "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/1.21/deploy.yaml"
  # }

}

resource "yandex_vpc_network" "k8s-network" { name = "k8s-network" }

resource "yandex_vpc_subnet" "k8s-subnet" {
 v4_cidr_blocks = [var.cidr_nodes]
 zone           = var.zone
 network_id     = yandex_vpc_network.k8s-network.id
}

resource "yandex_iam_service_account" "k8s-account" {
 name        = "k8s-account"
 description = "Аккаунт для управления k8s"
 folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
 # Сервисному аккаунту назначается роль "editor".
 folder_id = var.folder_id
 role      = "editor"
 members   = [
   "serviceAccount:${yandex_iam_service_account.k8s-account.id}"
 ]
}

resource "yandex_resourcemanager_folder_iam_binding" "images-puller" {
 # Сервисному аккаунту назначается роль "container-registry.images.puller".
 folder_id = var.folder_id
 role      = "container-registry.images.puller"
 members   = [
   "serviceAccount:${yandex_iam_service_account.k8s-account.id}"
 ]
}

resource "yandex_kubernetes_node_group" "k8s-nodes-group" {
  cluster_id  = "${yandex_kubernetes_cluster.k8s-cluster.id}"
  name        = "k8s-nodes-group"
  description = "Группа узлов кластера Kubernetes"
  version     = "1.21"

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.k8s-subnet.id}"]
    }

    resources {
      memory = 8
      cores  = 4
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}

resource "null_resource" "provisioning" {
  depends_on = [yandex_kubernetes_node_group.k8s-nodes-group]
  provisioner "local-exec" {
    command = <<EOF
      set -e
      echo "Add k8s context"
      yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.k8s-cluster.name} --external --force
      
      #echo "Add ingress"
      #kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/1.21/deploy.yaml

      echo "Install gitlab"
      helm repo add gitlab https://charts.gitlab.io/
      helm upgrade --install gitlab gitlab/gitlab \
        --set global.hosts.domain=${var.main_domain} \
        --set certmanager-issuer.email=${var.cert_issuer_email} \
        --set gitlab-runner.runners.privileged=true
      
      echo "Getting ingress IP"
      export INGRESS_IP=$(while [[ ! "$(kubectl get ingress gitlab-webservice-default \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; \
        do sleep 1; done; \
      kubectl get ingress gitlab-webservice-default -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      echo "Ingress IP: $INGRESS_IP"

      echo "Changing domains IP"
      wget --no-check-certificate -O - \
        "https://${var.afraid_account}:${var.afraid_pass}@freedns.afraid.org/nic/update?hostname=${var.main_domain}&myip=$INGRESS_IP"
      
      export TOOLBOX_POD=$(kubectl get pod | grep gitlab-toolbox | awk '{print $1};')
      echo "toolbox pod: $TOOLBOX_POD"
      export WEB_POD=$(kubectl get pod | grep gitlab-webservice | head -n 1 | awk '{print $1};')
      echo "web service pod: $WEB_POD"
      echo "Wait for web service's running for workability acknowledgment"
      while [[ "$(kubectl get pod $WEB_POD -o jsonpath='{.status.phase}' || true)" != "Running" ]]
      do
        sleep 1
      done
      echo "Web service is running"
      
      echo "Issuing of root token"
      kubectl exec $TOOLBOX_POD -- gitlab-rails runner \
        'token = User.first.personal_access_tokens.create(scopes: [:api], name: "Automation token"); token.set_token("${var.automation_token}"); token.save!; puts "Token created";'
        
      echo "Wait for DNS records update"
      while [[ "$(nslookup gitlab.${var.main_domain} | grep -Po '(?<=Address: )(.+)$' || true)" != "$INGRESS_IP" ]]
      do
        sleep 1
      done
      sleep 15
    EOF
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "provisioning2" {
  depends_on = [yandex_kubernetes_node_group.k8s-nodes-group,null_resource.provisioning]
  provisioner "local-exec" {
    command = <<EOF
      set -e
      echo "Creating group"
      export GROUP_ID=$(curl -k --silent -H "Private-Token: ${var.automation_token}" -XPOST \
        "https://gitlab.${var.main_domain}/api/v4/groups?name=${var.repos_group_name}&path=${var.repos_group_name}" | jq '.id')
      echo $GROUP_ID

      echo "Setting variables"
      curl -k --silent -H "Private-Token: ${var.automation_token}" -XPOST \
        "https://gitlab.${var.main_domain}/api/v4/groups/$GROUP_ID/variables?key=CI_REGISTRY_USER" \
        -H "Content-Type:application/json" --data "{\"value\":\"${var.docker_account}\"}"
      curl -k --silent -H "Private-Token: ${var.automation_token}" -XPOST \
        "https://gitlab.${var.main_domain}/api/v4/groups/$GROUP_ID/variables?key=CI_REGISTRY_PASSWORD&masked=true" \
         -H "Content-Type:application/json" --data "{\"value\":\"${var.docker_pass}\"}"
      curl -k --silent -H "Private-Token: ${var.automation_token}" -XPOST \
        "https://gitlab.${var.main_domain}/api/v4/groups/$GROUP_ID/variables?key=APP_DOMAIN" \
         -H "Content-Type:application/json" --data "{\"value\":\"${var.main_domain}\"}"

      REPOS="Crawler UI Deploy Monitoring"
      echo "Creating repos"
      for PROJ in $REPOS
      do
        echo "Creating repo $PROJ"
        export PROJECT_ID=$(curl -k --silent -H "Private-Token: ${var.automation_token}" -XPOST \
          "https://gitlab.${var.main_domain}/api/v4/projects?name=$PROJ&visibility=public&initialize_with_readme=false&namespace_id=$GROUP_ID" | jq '.id')
        echo $PROJECT_ID
        if [[ ! -n "$PROJECT_ID" ]]; then exit 1; fi
        export AGENT_ID=$(curl -k --silent -H "Private-Token: ${var.automation_token}" -XPOST \
          "https://gitlab.${var.main_domain}/api/v4/projects/$PROJECT_ID/cluster_agents?name=gitlab-ci-agent-$(echo "$PROJ" | tr '[:upper:]' '[:lower:]')" | jq '.id')
        echo $AGENT_ID
        export AGENT_TOKEN=$(curl -k --silent -H "Private-Token: ${var.automation_token}" -XPOST \
          "https://gitlab.${var.main_domain}/api/v4/projects/$PROJECT_ID/cluster_agents/$AGENT_ID/tokens?name=app-token" | jq -r '.token')
        echo $AGENT_TOKEN
        helm upgrade --install gitlab-ci-agent-$(echo "$PROJ" | tr '[:upper:]' '[:lower:]') gitlab/gitlab-agent \
          --set image.tag=v15.2.0 --set config.token="$AGENT_TOKEN" --set config.kasAddress=wss://kas.${var.main_domain}
      done
      
      echo "Adding SSH key"
      curl -k --silent -H "Private-Token: ${var.automation_token}" -XPOST \
        "https://gitlab.${var.main_domain}/api/v4/user/keys?title=ssh-cert" \
        -H "Content-Type:application/json" --data "{\"key\":\"$(cat ${var.public_key_path})\"}"
      
      echo "Clearing repos dir"
      echo "${var.local_repos_dir}/*"
      rm -rf ${var.local_repos_dir}/*

      echo "Filling projects' files"
      for PROJ in $REPOS
      do
        echo "Filling $PROJ"
        PROJ_LOW=$(echo "$PROJ" | tr '[:upper:]' '[:lower:]')
        mkdir -p ${var.local_repos_dir}/$PROJ_LOW
        cd ${var.local_repos_dir}/$PROJ_LOW
        git init
        git remote add origin git@gitlab.${var.main_domain}:${var.repos_group_name}/$PROJ.git
        git checkout -b main
        cp -rf ${abspath(path.root)}/../../src/$PROJ_LOW ${var.local_repos_dir}
        echo "Containment: $(ls)"
        git add .
        git commit -m "Initial commit"
        GIT_SSH_COMMAND="ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no" git push --set-upstream origin main
      done

      echo "Obtaining root password"
      ROOT_PASS="$(kubectl get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d)"

      echo "Everything is done. You can connect to gitlab.${var.main_domain} with root password:\n $ROOT_PASS"
      echo "Use path ${var.local_repos_dir} for application repository maintainance. Run next command for appropriate access:"
      echo "export GIT_SSH_COMMAND=\"ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no\""
    EOF
    interpreter = ["/bin/bash", "-c"]
  }
}