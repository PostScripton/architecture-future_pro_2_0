# Идентификаторы облака и каталога заменить на свои
cloud_id  = "b1gxxxxxxxxxxxxxxxxx"
folder_id = "b1gssssssssssssssssss"
zone      = "ru-central1-b"

name          = "future20-app-stage"
cores         = 4
memory        = 8
core_fraction = 100

subnet_id = "e9bxxxxxxxxxxxxstage"
nat       = false

image_id       = "fd80xxxxxxxxxxxxxxxx"
boot_disk_size = 30
boot_disk_type = "network-ssd"

attached_disk_size = 100
attached_disk_type = "network-ssd"

preemptible = false

ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleStageKeyReplaceMeXXXXXXXXXXXXXXXXXX stage@future20"

labels = {
  env     = "stage"
  project = "future20"
}
