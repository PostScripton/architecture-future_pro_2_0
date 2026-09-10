# Идентификаторы облака и каталога заменить на свои
cloud_id  = "b1gxxxxxxxxxxxxxxxxx"
folder_id = "b1gdddddddddddddddddd"
zone      = "ru-central1-a"

name          = "future20-app-dev"
cores         = 2
memory        = 2
core_fraction = 20

subnet_id = "e9bxxxxxxxxxxxxxxdev"
nat       = true

image_id       = "fd80xxxxxxxxxxxxxxxx"
boot_disk_size = 20
boot_disk_type = "network-hdd"

attached_disk_size = 20
attached_disk_type = "network-hdd"

preemptible = true

ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleDevKeyReplaceMeXXXXXXXXXXXXXXXXXXXX dev@future20"

labels = {
  env     = "dev"
  project = "future20"
}
