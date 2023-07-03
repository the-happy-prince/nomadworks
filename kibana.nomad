job "kibana" {
  type        = "service"
  datacenters = ["dc1"]

  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "180s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
    auto_revert = true
    auto_promote = true
    canary = 1
  }

  group "dj_kibana" {
    count = 1

    network {
        mode = "host"
        port "http" {
              to = 5601
              static = 5601
          }
    }

    task "kibana_container" {
      driver = "docker"
      kill_timeout = "600s"
      kill_signal = "SIGTERM"


      template {
          data = <<EOH
server.host: 0.0.0.0
server.ssl.enabled: false
elasticsearch.hosts: "http://{{ range service "elasticsearch" }}{{ .Address }}:{{ .Port }}{{ end }}"
elasticsearch.username: djspacewise
elasticsearch.password: 'djspacewise'
          EOH
  
          destination = "local/kibana/kibana.yml"
        }

      config {
        image = "docker.elastic.co/kibana/kibana:7.1.0"
        command = "kibana"
        ports = ["http"]
        volumes = [
          "local/kibana/kibana.yml:/usr/share/kibana/config/kibana.yml",
        ]

        ulimit {
            memlock = "-1"
            nofile  = "65536"
            nproc   = "8192"
          }
      }

      service {
        name = "kibana"
        port = "http"
        tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.kibrouter.rule=Host(`domain.name`)"
        ]
      }
  
        resources {
          cpu    = 1024
          memory = 2048
        }
    }
  }
}