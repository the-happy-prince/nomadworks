  job "rabbitmq" {

    datacenters = ["dc1"]
    type = "service"

    group "cluster" {
      count = 1

      update {
        max_parallel = 1
      }

      migrate {
        max_parallel = 1
        health_check = "checks"
        min_healthy_time = "5s"
        healthy_deadline = "30s"
      }

      network {
        mode = "host"
          port "ui" {
              to = 15672 
              static = 15672 
          } 
          port "amqp" { 
              to = 5672 
              static = 5672 
          }
          port "metric" { 
              to = 15692 
              static = 15692
          }
          dns {
          servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
        }
      }


      task "rabbit" {
        driver = "docker"

        config {
          image = "rabbitmq:3.11-management"
          hostname = "${attr.unique.hostname}"
          ports = ["ui", "amqp", "metric" ]
        }

        resources {
          cpu    = 4096 # Mhz
          memory = 4096 # MB
        }

        service {
          name = "rabbitmq"
          port = "amqp"
          provider = "consul"
          tags = [ 
            "traefik.enable=true",
            "traefik.http.routers.rabbitrouter.rule=Host(`domain.name`)"
          ]
        }

        service {
          name = "rabbitmq-ui"
          port = "ui"
          provider = "consul"
          tags = [ 
            "traefik.enable=true",
            "traefik.http.routers.rabbituirouter.rule=Host(`domain.name`)"
          ]
        }

        service {
          name = "prometheus"
          port = "metric"
          provider = "consul"
        }

      }
    }
  }
