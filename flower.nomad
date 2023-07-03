variable "flower_ip" {
  type = string
  default = "192.46.209.48/32"
}

job "flowermonitor" {
  datacenters = ["dc1"]
  type        = "service"

  group "flower" {
    count = 1
    update {
      max_parallel     = 1
      canary           = 1
      min_healthy_time = "30s"
      healthy_deadline = "5m"
      auto_revert      = true
      auto_promote     = false
    }
    network {
      mode = "host"
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }
       port "http" {
        to = 5555
      }
    }

    task "flower" {
      driver = "docker"

      config {
        image = "mher/flower:latest"
        ports = [
          "http"
        ]
        command = "celery"
        args = [ "--broker=${BROKER_URL}", "flower","--broker-api=${BROKER_API}" ]
        volumes = [
          "local/nomad.env:/dj_spacewise/devops/nomad.env"
        ]
      }

      resources {
        cpu    = 500
        memory = 256 
      }

      template {
        destination = "local/docker.env"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{ range service "rabbitmq" }}
BROKER_URL=amqp://guest:guest@{{.Address}}:{{.Port}}//
BROKER_API=http://guest:guest@{{.Address}}:{{.Port}}/api//
{{ end }}
EOF
     }

      service {
        name = "flower"
        port = "http"
        address_mode = "auto"
        tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.flowerrouter.rule=Host(`domain.name`)",
          "traefik.http.routers.flowerrouter.middlewares=ipwhitelist-test@consulcatalog",
          "traefik.http.middlewares.ipwhitelist-test.ipwhitelist.sourcerange=${var.flower_ip}",
          "traefik.http.middlewares.ipwhitelist-test.ipwhitelist.ipstrategy.depth=1",
        ]
        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
