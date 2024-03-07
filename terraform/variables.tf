  variable "vultr_api_key" {
    type      = string
    sensitive = true
  }


  variable "region" {
    description = "Vultr Region"
    type        = string
    default     = "your_region"
  }

  variable "plan" {
    description = "Vultr Plan"
    type        = string
    default     = "your_plan"
  }

  variable "snapshot_id" {
    description = "Vultr Operating System ID"
    type        = string
  }

  variable "private_network_label" {
    description = "Label for the private network"
    type        = string
    default     = "nomad-network"
  }

  variable "nomad_server_hostname_prefix" {
    description = "Prefix for Nomad Server hostnames"
    type        = string
    default     = "nomad-server"
  }

  variable "nomad_client_hostname_prefix" {
    description = "Prefix for Nomad Client hostnames"
    type        = string
    default     = "nomad-client"
  }

  variable "lb_server_name" {
    description = "Name for Nomad Servers Load Balancer"
    type        = string
    default     = "nomad-servers-lb"
  }

  variable "lb_client_name" {
    description = "Name for Nomad Clients Load Balancer"
    type        = string
    default     = "nomad-clients-lb"
  }
