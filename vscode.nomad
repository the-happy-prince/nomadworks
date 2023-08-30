job "vscode" {
  datacenters = ["dc1"]
  type = "service"

  group "vscode"{
    count = 1
    spread {
      attribute = "${node.unique.id}"
    }
    network {
      mode = "host"
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }

      port "http" {
        to = 3000
      }
    }

  task "vscode" {
    driver = "docker"

    config {
      image = "gitpod/openvscode-server"
      ports = [
        "http"
      ]
      volumes = [
        "local:/home/workspace:cached"
      ]
    }

    resources {
      cpu = 1024
      memory = 1024 
    }

    service {
        name = "vscode"
        port = "http"
        provider = "consul"
        tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.vscoderouter.rule=Host(`code.anytypecompute.com`)"
          ]

        }
  }
  }
}
