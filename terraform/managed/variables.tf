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
  description = "Path to the public key used for ssh access. It has to be in you .ssh directory"
}
variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}
variable "server_user" {
  description = "User for connection to all servers"
  default     = "ubuntu"
}
variable "main_domain" {
  description = <<EOF
    Main domain all resources will created within. For example yunusovtr.my.to.
    It has to be previously registered on afraid.com with its subdomains with strict names:
     - gitlab
     - minio
     - kas
     - registry
    And all of those have to be associated to one but any IP address.
    EOF
  default     = "example.com"
}
variable "cert_issuer_email" {
  description = "Email of issuer for certificate registration"
  default     = "admin@example.com"
}
variable "afraid_account" {
  description = "Account on site afraid.com"
  default     = ""
}
variable "afraid_pass" {
  description = "Password for account on site afraid.com"
  default     = ""
}
variable "automation_token" {
  description = "I was lazy for writing token generator but not for adding it as variable"
  default     = "HereShouldBeGeneratedToken"
}
variable "local_repos_dir" {
  description = "Directory for local projects retaining"
  default     = "/tmp/repos"
}
variable "docker_account" {
  description = "Account for pushing to docker official repositary"
}
variable "docker_pass" {
  description = "Password of account for pushing to docker official repositary"
}
variable "repos_group_name" {
  description = "Name of groups of repositories"
  default     = "devops-project"
}