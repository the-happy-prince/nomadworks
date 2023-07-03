variable "grafana_ip" {
  type = string
  default = "192.46.209.48/32"
}

job "grafana" {
  datacenters = ["dc1"]
  type        = "service"


  group "grafana" {
    count = 1

    network {
      mode = "host"
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }

      port "http" {
        to = 3000
      }
    }

    service {
      name = "grafana"
      port = "http" 
      provider="consul"
      tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.grafanarouter.rule=Host(`domain.name`)",
          "traefik.http.routers.grafanarouter.middlewares=ipwhitelist-test2@consulcatalog",
          "traefik.http.middlewares.ipwhitelist-test2.ipwhitelist.sourcerange=${var.grafana_ip}",
          "traefik.http.middlewares.ipwhitelist-test2.ipwhitelist.ipstrategy.depth=1"
      ]
    }

    task "grafana" {
      driver = "docker"

      env {
        GF_SECURITY_ADMIN_PASSWORD = "zdrgnko123"
      }

      config {
        image   = "grafana/grafana:9.5.1"
        ports   = ["http"]
      }

      resources {
        cpu    = 500
        memory = 512
      }

    }

  }

}