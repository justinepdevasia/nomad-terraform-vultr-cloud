#!/usr/bin/env bash
set -Eeuo pipefail

# Enables nomad systemd service
start_nomad() {
  sudo systemctl enable --now nomad
  sudo systemctl restart nomad
}

# Sets up `/etc/nomad.d`
prepare_nomad_client_config() {
  cat <<EOF >/etc/nomad.d/nomad.hcl
datacenter = "dc1"
data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"
log_level = "INFO"
    
advertise {
  http = "{{ GetInterfaceIP \"enp8s0\" }}"
  rpc  = "{{ GetInterfaceIP \"enp8s0\" }}"
  serf = "{{ GetInterfaceIP \"enp8s0\" }}"
}


# Enable the client
client {
  enabled = true
  options {
    "driver.raw_exec.enable"    = "1"
    "docker.privileged.enabled" = "true"
  }
  server_join {
    retry_join = [ "${nomad_server_private_ips}" ]
  }

  network_interface = "enp8s0"

  chroot_env {
    # Defaults
    "/bin/"           = "/bin/"
    "/lib"            = "/lib"
    "/lib32"          = "/lib32"
    "/lib64"          = "/lib64"
    "/sbin"           = "/sbin"
    "/usr"            = "/usr"
    
    "/etc/ld.so.cache"  = "/etc/ld.so.cache"
    "/etc/ld.so.conf"   = "/etc/ld.so.conf"
    "/etc/ld.so.conf.d" = "/etc/ld.so.conf.d"
    "/etc/localtime"    = "/etc/localtime"
    "/etc/passwd"       = "/etc/passwd"
    "/etc/ssl"          = "/etc/ssl"
    "/etc/timezone"     = "/etc/timezone"

  }
}

plugin "exec" {
  config {
    allow_caps = ["audit_write", "chown", "dac_override", "fowner", "fsetid", "kill", "mknod",
    "net_bind_service", "setfcap", "setgid", "setpcap", "setuid", "sys_chroot", "sys_time"]
  }
}

plugin "docker" {
  config {
    endpoint = "unix:///var/run/docker.sock"

    extra_labels = ["job_name", "job_id", "task_group_name", "task_name", "namespace", "node_name", "node_id"]

    volumes {
      enabled      = true
      selinuxlabel = "z"
    }

    # auth {
    #   # Nomad will prepend "docker-credential-" to the helper value and call
    #   # that script name.
    #   config = "/etc/docker/config.json"
    # }

    allow_privileged = true
    // allow_caps       = ["chown", "net_raw"]
  }
}

telemetry {
  collection_interval = "15s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

EOF
}

# prepare_docker_auth_config() {
#     cat <<EOF >/etc/docker/config.json
# {
#   "credsStore": "ecr-login"
# }
# EOF
# }


# prepare_docker_auth_config
prepare_nomad_client_config
start_nomad