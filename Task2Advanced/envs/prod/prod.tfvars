# Идентификаторы облака и каталога заменить на свои
cloud_id  = "b1gxxxxxxxxxxxxxxxxx"
folder_id = "b1gpppppppppppppppppp"
zone      = "ru-central1-a"

name          = "future20-app-prod"
cores         = 8
memory        = 32
core_fraction = 100

subnet_id = "e9bxxxxxxxxxxxxxprod"
nat       = false

image_id       = "fd80xxxxxxxxxxxxxxxx"
boot_disk_size = 50
boot_disk_type = "network-ssd"

attached_disk_size = 500
attached_disk_type = "network-ssd"

preemptible = false

ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleProdKeyReplaceMeXXXXXXXXXXXXXXXXXXX prod@future20"

labels = {
  env     = "prod"
  project = "future20"
}
