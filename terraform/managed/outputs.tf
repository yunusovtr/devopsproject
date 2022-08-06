
# output "external_k8s_master" {
#   value = yandex_compute_instance.node.0.network_interface.0.nat_ip_address
# }

# output "external_k8s_nodes" {
#   value = yandex_compute_instance.node.*.network_interface.0.nat_ip_address
# }

# output "external_storage" {
#   value = yandex_compute_instance.storage.network_interface.0.nat_ip_address
# }

# output "local_nodes" {
#   value = yandex_compute_instance.node.*.network_interface.0.ip_address
# }

# output "local_storage" {
#   value = yandex_compute_instance.storage.network_interface.0.ip_address
# }

# # Генерируем Ansible инвентори
# resource "local_file" "ansible_inventory" {
#   content = templatefile("inventory.tftpl",
#     {
#       storage_local_ip = yandex_compute_instance.storage.network_interface.0.ip_address
#       storage_public_ip = yandex_compute_instance.storage.network_interface.0.nat_ip_address
#       nodes_ip        = yandex_compute_instance.node.*.network_interface.0.nat_ip_address
#       local_ip        = yandex_compute_instance.node.*.network_interface.0.ip_address
#       private_key     = var.private_key_path
#       server_user     = var.server_user
#       cidr            = var.cidr_nodes
#     }
#   )
#   filename = "../../ansible/environments/manage/inventory/from_terraform"
# }