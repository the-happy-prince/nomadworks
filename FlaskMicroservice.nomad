job "flask_image_thumbnail" {
  datacenters = ["dc1"]
  type = "service"

  group "app"{
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
        to = 5015
        static = 5015
      }
    }
  task "app" {
    driver = "docker"

    config {
      image = "image"
      ports = [
        "http"
      ]
    }

    resources {
      cpu = 1024
      memory = 1024 
    }

    service {
        name = "imagethumbnail"
        port = "http"
        provider = "consul"
        }
  }
  }
}
