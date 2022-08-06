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
  provisioner "local-exec" {
    command = "yc managed-kubernetes cluster get-credentials ${self.name} --external --force"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/1.21/deploy.yaml"
  }
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
