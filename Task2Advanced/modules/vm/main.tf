terraform {
  required_version = ">= 1.5"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100"
    }
  }
}

resource "yandex_compute_disk" "data" {
  name   = "${var.name}-data"
  type   = var.attached_disk_type
  zone   = var.zone
  size   = var.attached_disk_size
  labels = var.labels
}

resource "yandex_compute_instance" "this" {
  name        = var.name
  zone        = var.zone
  platform_id = "standard-v3"
  labels      = var.labels

  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.boot_disk_size
      type     = var.boot_disk_type
    }
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.data.id
    auto_delete = false
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = var.nat
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_key}"
  }
}
