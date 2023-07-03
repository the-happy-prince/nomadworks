job "mongo" {
  datacenters = ["dc1"]
  type = "service"

  group "mongo" {
    count = 1
    spread {
      attribute = "${node.unique.id}"
    }
    network {
      mode = "host"
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }
       port "mongo" {
        to = 27017
        static = 27017
      }
    }
    task "mongo" {
      driver = "docker"

      config {
        image = "mongo:4.4"
        ports = [
          "mongo"
        ]
      }

      resources {
        cpu    = 2048
        memory = 2048
      }

      service {
        name = "mongo"
        port = "mongo"
        provider="consul"
      }
    }
  }
}
