job "authelia" {
  datacenters = ["dc1"]
  type = "service"

  group "authelia"{
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
        to = 9091
        static = 9091
      }
    }
  task "authelia" {
    driver = "docker"

    config {
      image = "authelia/authelia:latest"
      ports = [
        "http"
      ]
      volumes = [
        "./authelia:/config"
      ]
    }

    env{
    }

    resources {
      cpu = 200
      memory = 256 
    }
    
    template {
        data        = file(abspath("./authelia/configuration.yml"))
        destination = "/authelia/configuration.yml"
        change_mode = "restart"
      }

    template {
        data        = file(abspath("./authelia/users_database.yml"))
        destination = "/authelia/users_database.yml"
        change_mode = "restart"
      }

    service {
        name = "authelia"
        port = "http"
        provider = "consul"
        tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.authenticatingrouter.rule=Host(`authelia.anytypecompute.com`)",
          "traefik.http.middlewares.authelia.forwardauth.trustForwardHeader=true",
          "traefik.http.middlewares.authelia.forwardauth.address=https://authelia.anytypecompute.com/api/verify?rd=https://authelia.anytypecompute.com",
          "traefik.http.middlewares.authelia.forwardauth.authResponseHeaders=Remote-User,Remote-Groups,Remote-Name,Remote-Email"          ]

        }
  }
  }
}