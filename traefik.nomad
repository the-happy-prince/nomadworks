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
          "--entryPoints.web.address=:80",
          "--entryPoints.http.transport.lifeCycle.requestAcceptGraceTimeout=15s",
          "--entryPoints.http.transport.lifeCycle.graceTimeOut=10s",
          "--entryPoints.http.forwardedHeaders.insecure",
          "--entrypoints.websecure.address=:443",
          // "--entryPoints.admin.address=:8080",
          // "--entryPoints.admin.transport.lifeCycle.requestAcceptGraceTimeout=15s",
          // "--entryPoints.admin.transport.lifeCycle.graceTimeOut=10s",
          "--accesslog=true",
          "--api=true",
          "--api.insecure=true",
          "--api.dashboard=true",
          // "--metrics=true",
          // "--metrics.prometheus=true",
          // "--metrics.prometheus.entryPoint=admin",
          // "--metrics.prometheus.manualrouting=true",
          // "--ping=true",
          // "--ping.entryPoint=admin",
          "--providers.consulcatalog=true",
          "--providers.consulcatalog.endpoint.address=http://172.17.0.1:8500",
          "--providers.consulcatalog.prefix=traefik",
          // "--providers.consulcatalog.scheme=http",
          //"--providers.consulcatalog.endpoint.token=123e4567-e89b-12d3-a456-426614174000",
          "--providers.docker=true",
          "--certificatesresolvers.letsencrypt.acme.email=your@mail.com",
          "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json",
          "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=http",
          "--certificatesresolvers.letsencrypt.acme.tlschallenge=true",
          "--entrypoints.websecure.http.redirections.entrypoint.to=https",
          "--entrypoints.websecure.http.redirections.entrypoint.scheme=https",
        ]
        ports = ["http", "https", "admin"]
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
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
