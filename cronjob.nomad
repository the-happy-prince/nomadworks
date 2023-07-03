job "mongoscript" {
  datacenters = ["dc1"]
  type = "batch"

  periodic {
    // Launch every 20 seconds
    cron = "0 */6 * * *"

    // Do not allow overlapping runs.
    prohibit_overlap = true
  }

  group "cronjobname"{
    count = 1
    spread {
      attribute = "${node.unique.id}"
    }
    network {
      mode = "host"
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }

    }
  task "cronjobname" {
    driver = "docker"

    config {
      image = ""
      volumes = [
        "local/nomad.env:/project/devops/nomad.env"
      ]
    }

    env {
        LOAD_SCRIPT = "True"
        IS_DOCKER_ENV = "True"
        START_CELERY = "False"
    }

    template {
        destination = "local/docker.env"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/cronjobjobname" -}}

DATABASE_ENGINE={{.DATABASE_ENGINE}}
DATABASE_NAME={{.DATABASE_NAME}}
DATABASE_USER={{.DATABASE_USER}}
DATABASE_PASSWORD={{.DATABASE_PASSWORD}}
DATABASE_HOST={{.DATABASE_HOST}}
DATABASE_PORT={{.DATABASE_PORT}}
DEFAULT_MONGO_CONNECTION={{.DEFAULT_MONGO_CONNECTION}}
{{- end -}}
{{ range service "elasticsearch" }}
ELASTICSEARCH_HOST={{ .Address }}:{{ .Port }}
{{ end }}
{{range service "mongo" }}
MONGO_DATABASE_URL=mongodb://{{ .Address }}:{{ .Port }}
{{ end }}
{{ range service "rabbitmq" }}
CELERY_BROKER_URL=amqp://guest:guest@{{.Address}}:{{.Port}}/
CELERY_RESULT_BACKEND=rpc://guest:guest@{{.Address}}:{{.Port}}/
{{- end -}}
{{ range service "redis" }}
REDIS_HOST={{.Address}}
REDIS_PORT={{.Port}}
{{ end }}
EOF
     }
    resources {
      cpu = 4096
      memory = 2048 
    }

  }
  }
}