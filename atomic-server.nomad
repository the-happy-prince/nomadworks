job "atomic_server" {
  datacenters = ["dc1"]
  type = "service"

  group "atomic_server"{
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
        to = 80
      }
      
      port "https" {
        to = 443
      }
    }
  task "atomic_server" {
    driver = "docker"

    config {
      image = "joepmeneer/atomic-server"
      ports = ["http", "https"]
      volumes = ["atomic-storage:/atomic-storage"] 
    }
    resources {
      cpu = 1024
      memory = 1024 
    }

    service {
        name = "atomicserver"
        port = "http"
        provider = "consul"
        tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.atomicserver.rule=Host(`atomicserver.anytypecompute.com`)"
          ]
  }
  }
}
}