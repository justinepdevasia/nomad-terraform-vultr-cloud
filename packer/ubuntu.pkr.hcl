 variable "vultr_api_key" {
   type      = string
   default   = "${env("VULTR_API_KEY")}"
   sensitive = true
 }

 packer {
   required_plugins {
     vultr = {
       version = ">=v2.3.2"
       source = "github.com/vultr/vultr"
     }
   }
 }

 source "vultr" "ubuntu-nomad" {
   api_key              = "${var.vultr_api_key}"
   os_id                = "2179"
   plan_id              = "vc2-1c-2gb"
   region_id            = "bom"
   snapshot_description = "Ubuntu 23.04 Nomad ${formatdate("YYYY-MM-DD hh:mm", timestamp())}"
   ssh_username         = "root"
   state_timeout        = "25m"
 }

 build {
   sources = ["source.vultr.ubuntu-nomad"]

   provisioner "shell" {
     script = "setup.sh"
   }
 }