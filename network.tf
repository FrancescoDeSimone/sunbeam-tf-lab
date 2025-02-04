resource "lxd_network" "oam" {
  name = "oam"

  config = {
    "ipv4.address" = "10.150.19.1/24"
    "ipv4.nat"     = "true"
  }
}
