variable "instance_count" {
  type    = number
  default = 1
}

resource "lxd_project" "sunbeam" {
  name        = "sunbeam"
  description = "sunbeam demo"
}

locals {
  cloud_init = <<EOT
#cloud-config
users:
  - name: ubuntu
    ssh_authorized_keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCKZc6GLae5vmRYjb78j1jJaHyCqMcQcTiEBJpVSIyHsjKS9UoGCDe3I8MXrkB+cdTCGexG+xifKi/ZoxgcJyIRx3dZgdTNiDwmgMsSqpxBuyhBWFMLM0GWWXcK48VCBxOADNgGepTVv28tzaCXYFNJfFpeq+pmveU84m3258JD60fAMyn4pxyokMoWanZ0KRHE+B/TIfRW4X8M+GXr//aAgAR5YVCM/zNhEfojrGMV5eGMzgPPaZLA719Z2sNqvZ/pSGUM+x8jLv4oTrUvmStNhtpicoIMDOwlHalHtxpJ4Cda6U5cggpfQiUppyhSBbhVBvyFLLH7zmUuRckmQdew47W9o2EAIHJ6KNEQ1UcbhkCrpxXkHwYE2SNnXE+We84uLR7D+HJzcIq2QD5akHSvaacOyH5GCEziRvMNNNwtHCfh7m8bUaZmSCCbvfkgpCNM6z5XOP1Zc79tLcMbXIusHTZ+wwMuugn6IW6HVZdED5upbCZTQlt6um9m+u4+zI0= fdesi@fdesi-ws
    sudo: ALL=(ALL) NOPASSWD:ALL
runcmd:
- su ubuntu -c "sudo snap install openstack --channel 2024.1/beta"
- su ubuntu -c "sudo systemctl start user@1000"
- su ubuntu -c "sudo -i -u ubuntu sunbeam prepare-node-script --bootstrap  bash -x"
- su ubuntu -c "sudo -i -u ubuntu sunbeam cluster bootstrap --accept-defaults"

EOT
}

resource "lxd_instance" "instance" {
  for_each = toset([for i in range(var.instance_count) : "vm-${i + 1}"])
  name     = each.key
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  project  = lxd_project.sunbeam.name
  config = {
    "cloud-init.user-data" = local.cloud_init
  }
  limits = {
    cpu    = 4
    memory = "16GiB"
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = "${lxd_network.oam.name}"
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }
}
