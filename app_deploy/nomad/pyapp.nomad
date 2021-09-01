job "pyapp" {
  datacenters = ["dc1"]

  group "checkout" {
    count = 4

    network {
      mode = "bridge"
    }

    service {
      name = "prod-checkout"
      port = "5001"
      check {
        type = "http"
        path = "/"
        interval = "5s"
        timeout = "2s"
        expose = true
      }

      connect {
        sidecar_service {
            proxy {
            }
        }
      }
    }

    task "checkout" {
      driver = "docker"
      config {
        image = "dgkirkwood/checkout:latest"
      }
    }
  }

  group "recommendations" {
    count = 5
    network {
      mode = "bridge"
    }

    service {
      name = "prod-recommendations"
      port = "5002"

      connect {
        sidecar_service {
            proxy {
            }
        }
      }
    }

    task "recommendations" {
      driver = "docker"
      config {
        image = "dgkirkwood/recommendations:latest"
      }
    }
  }

  group "payments" {
    count = 5
    network {
      mode ="bridge"
    }

    spread {
      attribute = "${attr.platform.aws.placement.availability-zone}"
      target "ap-southeast-2a" {
        percent = 34
      }
      target "ap-southeast-2b" {
        percent = 33
      }
      target "ap-southeast-2c" {
        percent = 33
      }
    }

    service {
      name = "prod-payments"
      port = "5003"
      
      check {
        type = "http"
        path = "/"
        interval = "5s"
        timeout = "2s"
        expose = true
      }

      canary_tags = ["canary"]
      tags = ["${attr.platform.aws.placement.availability-zone}"]
      meta {
          version = "1.1"
          availability_zone = "${attr.platform.aws.placement.availability-zone}"
      }
      canary_meta {
          version = "canary"
      }

      connect {
        sidecar_service {
          proxy {
          }
        }
      }
    }
    update {
        max_parallel = 3
        health_check = "checks"
        min_healthy_time = "30s"
        healthy_deadline = "2m"
        auto_revert = true
        auto_promote = true
        canary = 2
    }

    task "payments" {
      driver = "docker"
      config {
        image = "dgkirkwood/payments:1.1"
      }
    }
  }

  group "frontend" {
    count = 2

    network {
      mode ="bridge"
    }

    service {
      name = "prod-frontend"
      port = "5000"

      connect {
        sidecar_service {
          proxy {
            upstreams {
                destination_name = "prod-checkout"
                local_bind_port = 5001
            }
            upstreams {
                destination_name = "prod-payments"
                local_bind_port = 5003
            }
            upstreams {
                destination_name = "prod-mysql"
                local_bind_port = 3306
            }
            upstreams {
                destination_name = "prod-recommendations"
                local_bind_port = 5002
            }
          }
        }
      }
    }

    task "frontend" {
      driver = "docker"
      env {
          PORT = "5000"
          HOST_IP = "${attr.unique.platform.aws.local-ipv4}"
      }
      config {
        image = "dgkirkwood/frontend:4.10"
      }
    }
  }

}



