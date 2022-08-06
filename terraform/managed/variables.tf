variable "cloud_id" {
  description = "Cloud"
}
variable "folder_id" {
  description = "Folder"
}
variable "zone" {
  description = "VM zone"
  default     = "ru-central1-a"
}
variable "token" {
  description = "token"
}
variable "node_count" {
  description = "Count of node instances to create"
  default     = 2
}
variable "node_disk_image" {
  description = "Disk image for nodes"
  default     = "fd8f1tik9a7ap9ik2dg1"
}
variable "cidr_nodes" {
  description = "Subnet for Kubernetes nodes"
  default     = "192.168.10.0/24"
}
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}
variable "server_user" {
  description = "User for connection to all servers"
  default     = "ubuntu"
}
