job "traefik-proxy" {
  datacenters = ["dc1"]
  type        = "system"

  update {
    max_parallel = 1
    stagger      = "1m"
    # Enable automatically reverting to the last stable job on a failed
    # deployment.
    auto_revert = true
  }

  group "traefik" {
    network {
      mode = "host"
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }
      port "http" {
        to = 80
        static = 80
      }

      port "https" {
        to = 443
        static = 443
      }

      port "admin" {
        to = 8080
        static = 8080
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.9"
        args = [
            "--api=true",
            "--api.dashboard=true",
            "--api.insecure=true",
            "--accesslog=true",
            "--providers.docker=true",
            "--providers.consulcatalog=true",
            "--providers.consulcatalog.endpoint.address=http://172.17.0.1:8500",
            "--entryPoints.web.address=:80",
            "--providers.consulcatalog.prefix=traefik",
            "--entrypoints.websecure.address=:443",
            "--certificatesresolvers.letsencrypt.acme.email=princeraj@tuta.io",
            "--certificatesresolvers.letsencrypt.acme.storage=./letsencrypt/acme.json",
            "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
        ]
        ports = ["http", "https", "admin"]
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock", 
          "./letsencrypt:/letsencrypt"
        ]
      }

      kill_timeout = "30s"

      resources {
        cpu    = 200 # Mhz
        memory = 200 # MB
      }

      service {
        name = "traefik"
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
