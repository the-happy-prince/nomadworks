job "redis" {

  datacenters = ["dc1"]
  type = "service"

  group "redis" {
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
        dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
       }
        port "redis_port" {  static = 6379 } 
    }


    task "redis" {
      driver = "docker"

      config {
        image = "redis:7.0.8"
        ports = [
            "redis_port"
        ]
      }

      resources {
        cpu    = 1024 # Mhz
        memory = 4096 # MB
      }

      service {
        name = "redis"
        port = "redis_port"
        provider = "consul"
      }

    }
  }
}
