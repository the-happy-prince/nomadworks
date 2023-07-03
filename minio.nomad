# A minimal job to troubleshoot Redis + sidecar combination
job "minio" {
  datacenters = ["dc1"]
  type        = "service"


  group "minio" {
    count = 1

    network {
      mode = "host"
      port "api" {
        to = 9000
      }
      port "console" {
        to = 9001
      }
    }

    service {
      name = "minio"
      port = "api"
    }

    service {
      name = "minio-console"
      port = "console" 
      provider="consul"
      tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.miniorouter.rule=Host(`domain.name`)"
      ]
    }

    service {
      name = "minio-api"
      port = "api" 
      provider="consul"
      tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.minioapirouter.rule=Host(`domain.name`)"
      ]
    }

    volume "minio" {
      type      = "host"
      read_only = false
      source    = "minio"
    }

    task "minio" {
      driver = "docker"

      env {
        MINIO_ROOT_USER     = "admin"
        MINIO_ROOT_PASSWORD = "topSecret"
      }

      config {
        image   = "quay.io/minio/minio"
        ports   = ["api", "console"] # Defined above, in `network` stanza
        command = "server"
        args    = [
          "/tmp/",
          "--address", ":${NOMAD_PORT_api}",
          "--console-address", ":${NOMAD_PORT_console}",
        ]
      }

      volume_mount {
        volume      = "minio"
        destination = "/opt/minio"
        read_only   = false
      }

      resources {
        cpu    = 500
        memory = 512
      }

    }

  }

}