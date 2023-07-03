variable "docker_image_url" {
  type = string
}
variable "domain" {
  type = string
}

job "atomic" {
  datacenters = ["dc1"]
  type = "service"

  group "atomic"{
    count = 1
    spread {
      attribute = "${node.unique.id}"
    }
    network {
      mode = "host"
      dns {
        servers = ["172.17.0.1", "8.8.8.8", "8.8.4.4"]
      }

      port "http" {
        to = 8234
        static = 8234
      }
    }
  task "atomic" {
    driver = "docker"

    config {
      image = var.docker_image_url
      ports = [
        "http"
      ]
    }

    env{
      STAGE = "docker"
      IS_DOCKER_ENV = "True"
    }

    template {
        destination = "local/docker.env"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/atomic" -}}
DJANGO_URL={{.DJANGO_URL}}
INGEST_JSON_URL={{.INGEST_JSON_URL}}
BASE_URL_PREFIX={{.BASE_URL_PREFIX}}
UPLOAD_TO_MINIO={{.UPLOAD_TO_MINIO}}
MINIO_BUCKET_NAME={{.MINIO_BUCKET_NAME}}
MINIO_URL={{.MINIO_URL}}
SECRET_KEY={{.SECRET_KEY}}
SECURE={{.SECURE}}
ACCESS_KEY={{.ACCESS_KEY}}
DEFAULT_DB={{.DEFAULT_DB}}
GLOBAL_DB={{.GLOBAL_DB}}
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
{{range service "aistojson" }}
AIS_TO_JSON=http://{{ .Address }}:{{ .Port }}/process/ais_to_json
{{ end }}
{{range service "aisxtojson" }}
AISX_TO_JSON=http://{{ .Address }}:{{ .Port }}/process/aisx_to_json
{{ end }}
{{range service "csvtojson" }}
CSV_TO_JSON=http://{{ .Address }}:{{ .Port }}/process/csv_to_json
{{ end }}
{{range service "nmeatojson" }}
NMEA_TO_JSON=http://{{ .Address }}:{{ .Port }}/process/nmea_to_json
{{ end }}
{{range service "4607tojson" }}
ST_4607_TO_JSON=http://{{ .Address }}:{{ .Port }}/process/4607_to_json
{{ end }}
{{range service "videotomp4" }}
VIDEO_TO_MP4=http://{{ .Address }}:{{ .Port }}/process/video_to_mp4
{{ end }}
{{range service "aistotext" }}
AIS_TO_TEXT=http://{{ .Address }}:{{ .Port }}/process/ais_to_text
{{ end }}
{{range service "aisxtotext" }}
AISX_TO_TEXT=http://{{ .Address }}:{{ .Port }}/process/aisx_to_text
{{ end }}
{{range service "csvtotext" }}
CSV_TO_TEXT=http://{{ .Address }}:{{ .Port }}/process/csv_to_text
{{ end }}
{{range service "nitftojpeg" }}
NITF_TO_JPEG=http://{{ .Address }}:{{ .Port }}/process/nitf_to_jpeg
{{ end }}
{{range service "nmeatotext" }}
NMEA_TO_TEXT=http://{{ .Address }}:{{ .Port }}/process/nmea_to_text
{{ end }}
{{range service "4607totext" }}
ST_4607_TO_TEXT=http://{{ .Address }}:{{ .Port }}/process/4607_to_text
{{ end }}
{{range service "imagetojpg" }}
IMAGE_TO_JPG=http://{{ .Address }}:{{ .Port }}/process/image_to_jpg
{{ end }}
{{range service "imagetojpg" }}
IMAGE_TO_JPG=http://{{ .Address }}:{{ .Port }}/process/image_to_jpg
{{ end }}
{{range service "imagethumbnail" }}
IMAGE_THUMBNAIL_PROCESSING=http://{{ .Address }}:{{ .Port }}/process/image_process/
{{ end }}
EOF
    }
    resources {
      cpu = 4096
      memory = 4096 
    }

    service {
        name = "atomic"
        port = "http"
        provider = "consul"
        tags = [ 
          "traefik.enable=true",
          "traefik.http.routers.garouter.rule=Host(`${var.domain}`)"
          ]

        }
  }
  }
}
