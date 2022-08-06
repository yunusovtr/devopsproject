resource "yandex_compute_instance" "node" {
  count = var.node_count

  name = "node${count.index}"
  zone = var.zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.node_disk_image
      size = 20
    }
  }

  # dynamic "secondary_disk" {
  #   for_each = count.index == 0 ? [] : [ 1 ]
  #   content {
  #     disk_id = yandex_compute_disk.secdisk[count.index - 1].id
  #   }
  # }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  
  allow_stopping_for_update = true
}

# resource "yandex_compute_disk" "secdisk" {
#   count    = var.node_count - 1

#   name     = "secdisk${count.index}"
#   type     = "network-ssd"
#   zone     = var.zone
#   size     = 50
# }

resource "yandex_vpc_network" "network1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "subnet1"
  zone           = var.zone
  network_id     = yandex_vpc_network.network1.id
  v4_cidr_blocks = [var.cidr_nodes]
}

resource "yandex_compute_instance" "storage" {

  name = "storage"
  zone = var.zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.node_disk_image
      size = 150
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  
  allow_stopping_for_update = true
}
