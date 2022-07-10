
resource "yandex_compute_instance" "nat_instance" {
  name = "nat-instance"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.nat_instance_disk_image
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

resource "yandex_compute_instance" "node" {
  count = var.node_count

  name = "node${count.index}"
  zone = var.zone

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = var.node_disk_image
      size = 40
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnet.id
    nat       = count.index == 0 ? true : false
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

resource "yandex_vpc_network" "network1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "private_subnet" {
  name           = "private_subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.network1.id
  v4_cidr_blocks = [var.cidr_nodes]
  route_table_id = yandex_vpc_route_table.nat_rt.id
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public_subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.network1.id
  v4_cidr_blocks = [var.cidr_nat]
}

resource "yandex_vpc_route_table" "nat_rt" {
  network_id = yandex_vpc_network.network1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat_instance.network_interface.0.ip_address
  }
}