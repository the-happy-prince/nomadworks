job "elasticsearch" {
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

  group "elasticsearch" {
    count = 1

    network {
        mode = "host"
        port "http" {
              to = 9200
              static = 9200
          }
          port "tcp" {
              to = 9300
              static = 9300
          }
    }

    task "elastic_container" {
      driver = "docker"
      kill_timeout = "600s"
      kill_signal = "SIGTERM"

      env {
        ES_JAVA_OPTS = "-Xms2g -Xmx2g"
      }

      template {
          data = <<EOH
                network.host: 0.0.0.0
                node.name: dj_elastic
                discovery.type: single-node
                xpack.security.enabled: false
                    
                http.cors.enabled : true
                http.cors.allow-origin: "/.*/"
                http.cors.allow-methods: OPTIONS, HEAD, GET, POST, PUT, DELETE
                http.cors.allow-credentials: true
                http.cors.allow-headers: X-Requested-With, X-Auth-Token, Content-Type, Content-Length, Authorization, Access-Control-Allow-Headers, Accept

                path.repo: ["/snapshots"]
          EOH
  
          destination = "local/elastic/elasticsearch.yml"
        }

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:7.1.0"
        command = "elasticsearch"
        ports = ["http","tcp"]
        volumes = [
          "local/elastic/snapshots:/snapshots",
          "local/elastic/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml",
        ]
        args = [
            "-Ecluster.name=dj_elastic",
            "-Ediscovery.type=single-node"
        ]

        ulimit {
          memlock = "-1"
          nofile = "65536"
          nproc = "8192"
        }
      }


      service {
        name = "elasticsearch"
        port = "http"
        tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.elasticrouter.rule=Host(`domain.name`)"
        ]
      }

      service {
        name = "elasticsearch-tcp"
        port = "http"
        tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.elastictcprouter.rule=Host(`domain2.name`)"
        ]
      }

      resources {
        cpu    = 1000
        memory = 8192
      }
    }
  }
}