terraform {
  required_version = ">= 1.5"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

module "vm" {
  source = "../../modules/vm"

  name               = var.name
  zone               = var.zone
  cores              = var.cores
  memory             = var.memory
  core_fraction      = var.core_fraction
  subnet_id          = var.subnet_id
  nat                = var.nat
  ssh_key            = var.ssh_key
  image_id           = var.image_id
  boot_disk_size     = var.boot_disk_size
  boot_disk_type     = var.boot_disk_type
  attached_disk_size = var.attached_disk_size
  attached_disk_type = var.attached_disk_type
  preemptible        = var.preemptible
  labels             = var.labels
}
