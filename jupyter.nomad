job "jupyter" {
    datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]

  group "jupyter-notebook" {
    count = 1
   network {
          port  "http"  {
            to = 8888
            static = 8888
          }
        }
    volume "jupyter" {
      type      = "host"
      read_only = false
      source    = "jupyter"
    }

    task "scipy" {
       
      driver = "docker"
      config {
        image = "jupyter/scipy-notebook"
        ports = ["http"]
      }
      
      volume_mount {
        volume      = "jupyter"
        destination = "/opt/jupyter"
        read_only   = false
      }


      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        cpu = 1000
        memory = 1024
      }
      
    }
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
   service {
        name = "jupyter-scipy"
        port = "http"
     	tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.jupyterrouter.rule=Host(`domain.name`)"
        ]
     }
  }
}
