terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
      version = "2.19.0"
    }
  }
}

provider "vultr" {
  api_key = var.vultr_api_key
}

resource "vultr_vpc2" "nomad_vpc" {
    description   = "nomad VPC"
    region        = var.region
    ip_block      = "10.0.0.0"
    prefix_length = 24
    ip_type       = "v4"
}

# Create Firewall Group
resource "vultr_firewall_group" "nomad_firewall_group" {
  description = "Nomad Firewall Group"
}

# Create Firewall Rule for Nomad Servers (allow traffic on port 4646)
resource "vultr_firewall_rule" "nomad_server_firewall_rule" {
  firewall_group_id = vultr_firewall_group.nomad_firewall_group.id
  protocol         = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "4646"
  notes            = "Allow Nomad Server traffic on port 4646"
}

resource "vultr_firewall_rule" "nomad_client_firewall_rule" {
  firewall_group_id = vultr_firewall_group.nomad_firewall_group.id
  protocol         = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "80"
  notes            = "Allow Nomad Server traffic on port 80"
}

# Create Nomad Server in the VPC
resource "vultr_instance" "nomad_server" {
  count     = 1
  region    = var.region
  plan      = var.plan
  snapshot_id = var.snapshot_id
  hostname  = "${var.nomad_server_hostname_prefix}-${count.index + 1}"
  vpc2_ids  = [vultr_vpc2.nomad_vpc.id]
  user_data = file("nomad_server.sh")
  tags = ["nomad-server"]
  firewall_group_id = vultr_firewall_group.nomad_firewall_group.id

}

# Create Nomad Clients (3 instances) in the VPC
resource "vultr_instance" "nomad_client" {
  count     = 1
  region    = var.region
  plan      = var.plan
  snapshot_id = var.snapshot_id
  hostname  = "${var.nomad_client_hostname_prefix}-${count.index + 1}"
  vpc2_ids  = [vultr_vpc2.nomad_vpc.id]
  user_data = templatefile("nomad_client.sh", { nomad_server_private_ips = vultr_instance.nomad_server[0].internal_ip })
  tags = ["nomad-client"]
  firewall_group_id = vultr_firewall_group.nomad_firewall_group.id

}

# Create Load Balancer for Nomad Servers
resource "vultr_load_balancer" "nomad_servers_lb" {
  region              = var.region
  label               = var.lb_server_name
  balancing_algorithm = "roundrobin"

  forwarding_rules {
    frontend_protocol = "http"
    frontend_port     = 80
    backend_protocol  = "http"
    backend_port      = 4646
  }

  firewall_rules {
    port = 80
    ip_type       = "v4"
    source  = "0.0.0.0/0"
  }

  health_check {
    protocol     = "tcp"
    port         = 4646
    check_interval = 5
    path         = "/"
  }

  attached_instances = vultr_instance.nomad_server[*].id
  vpc                = vultr_vpc2.nomad_vpc.id
}

# Create Load Balancer for Nomad Clients
resource "vultr_load_balancer" "nomad_clients_lb" {
  region              = var.region
  label               = var.lb_client_name
  balancing_algorithm = "roundrobin"

  forwarding_rules {
    frontend_protocol = "http"
    frontend_port     = 80
    backend_protocol  = "http"
    backend_port      = 80
  }

  firewall_rules {
    port = 80
    ip_type       = "v4"
    source  = "0.0.0.0/0"
  }

  health_check {
    protocol     = "http"
    port         = 80
    check_interval = 5
    path         = "/ping"
  }

  attached_instances = vultr_instance.nomad_client[*].id
  vpc                = vultr_vpc2.nomad_vpc.id
}

output "nomad_server_internal_ip" {
  value = vultr_instance.nomad_server[0].internal_ip
}
  
output "nomad_client_lb_ip" {
  value = vultr_load_balancer.nomad_clients_lb.ipv4
}

output "nomad_server_lb_ip" {
  value = vultr_load_balancer.nomad_servers_lb.ipv4
}