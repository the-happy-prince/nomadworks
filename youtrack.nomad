job "youtrack" {
  datacenters = ["dc1"]
  type        = "service"


  group "youtrack" {
    count = 1
    update {
      max_parallel     = 1
      canary           = 1
      min_healthy_time = "30s"
      healthy_deadline = "5m"
      auto_revert      = true
      auto_promote     = false
    }
    spread {
      attribute = "${node.unique.id}"
    }
    network {
      mode = "host"
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }
      port "http" {
        to = 8080
      }
    }

    service {
      name = "youtrack"
      port = "http"
      provider="consul"
      tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.youtrackrouter.rule=Host(`domain.name`)"
      ]
    }

    volume "youtrack_data" {
      type      = "host"
      read_only = false
      source    = "youtrack_data"
    }

    volume "youtrack_conf" {
      type      = "host"
      read_only = false
      source    = "youtrack_conf"
    }

    volume "youtrack_logs" {
      type      = "host"
      read_only = false
      source    = "youtrack_logs"
    }

    volume "youtrack_backups" {
      type      = "host"
      read_only = false
      source    = "youtrack_backups"
    }

    task "youtrack" {
      driver = "docker"

      config {
        image   = "jetbrains/youtrack:2023.1.10731"
        ports   = ["http"]
      }

      volume_mount {
        volume      = "youtrack_data"
        destination = "/opt/youtrack/data"
        read_only   = false
      }

      volume_mount {
        volume      = "youtrack_conf"
        destination = "/opt/youtrack/conf"
        read_only   = false
      }

      volume_mount {
        volume      = "youtrack_logs"
        destination = "/opt/youtrack/logs"
        read_only   = false
      }

      volume_mount {
        volume      = "youtrack_backups"
        destination = "/opt/youtrack/backups"
        read_only   = false
      }

      resources {
        cpu    = 2048
        memory = 2048
      }

    }

  }

}