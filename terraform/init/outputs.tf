output "external_ip_address" {
  value = yandex_compute_instance.nat_instance.network_interface.0.nat_ip_address
}

output "node0_external_ip_address" {
  value = yandex_compute_instance.node.0.network_interface.0.nat_ip_address
}

output "nat_instance_internal_ip" {
  value = yandex_compute_instance.nat_instance.network_interface.0.ip_address
}

output "internal_ip" {
  value = yandex_compute_instance.node.*.network_interface.0.ip_address
}

# Генерируем Ansible инвентори
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tftpl",
    {
      nat_instance_ip = "${yandex_compute_instance.nat_instance.network_interface.0.nat_ip_address}"
      node0_ip        = "${yandex_compute_instance.node.0.network_interface.0.nat_ip_address}"
      nodes_ip        = yandex_compute_instance.node.*.network_interface.0.ip_address
      private_key     = var.private_key_path
      server_user     = var.server_user
    }
  )
  filename = "../../ansible/environments/manage/inventory/from_terraform"
}