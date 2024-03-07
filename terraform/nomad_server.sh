#!/usr/bin/env bash
set -Eeuo pipefail

start_nomad() {
  sudo systemctl enable --now nomad
  sudo systemctl restart nomad
} 

prepare_nomad_server_config() {
  cat <<EOF >/etc/nomad.d/nomad.hcl
datacenter = "dc1"
data_dir   = "/opt/nomad/data"
bind_addr = "0.0.0.0"
log_level = "INFO"

advertise {
  http = "{{ GetInterfaceIP \"enp8s0\" }}"
  rpc  = "{{ GetInterfaceIP \"enp8s0\" }}"
  serf = "{{ GetInterfaceIP \"enp8s0\" }}"
}

server {
  enabled          = true
  bootstrap_expect = "1"
  encrypt          = "z8geXx7U+JPk6u/vlBRDhh81h5W12AXBN+7AUo5eXMI="
  server_join {
    retry_join = ["127.0.0.1"]
  }
  search {
    fuzzy_enabled   = true
    limit_query     = 200
    limit_results   = 1000
    min_term_length = 5
  }
}

acl {
  enabled = false
}

telemetry {
  collection_interval = "15s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

autopilot {
  cleanup_dead_servers      = true
  last_contact_threshold    = "200ms"
  max_trailing_logs         = 200
  server_stabilization_time = "10s"
  enable_redundancy_zones   = false
  disable_upgrade_migration = false
  enable_custom_upgrades    = false
}
EOF
}

prepare_nomad_server_config
start_nomad