job "gateways" {

  datacenters = ["dc1"]

  group "pyapp-ingress" {
      network {
          mode = "bridge"
          port "inbound" {
              static = 5000
              to = 5000
          }
      }

      service {
          name = "prod-ingress-gateway"
          port = "5000"
          connect {
            gateway {
                proxy {}
                ingress {
                    listener {
                        port = 5000
                        protocol = "tcp"
                        service {
                            name = "prod-frontend"
                        }
                    }
                }
            }
          }

      }
  }

  group "pyapp-terminating" {
      network {
          mode = "bridge"
      }

      service {
          name = "prod-terminating-gateway"
          connect {
            gateway {
                proxy {}
                terminating {
                  service {
                    name = "prod-mysql"
                  }
                }
            }
          }

      }
    }
}