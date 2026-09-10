output "instance_id" {
  description = "ID виртуальной машины"
  value       = yandex_compute_instance.this.id
}

output "instance_name" {
  description = "Имя виртуальной машины"
  value       = yandex_compute_instance.this.name
}

output "fqdn" {
  description = "FQDN виртуальной машины"
  value       = yandex_compute_instance.this.fqdn
}

output "internal_ip" {
  description = "Внутренний IP-адрес ВМ"
  value       = yandex_compute_instance.this.network_interface[0].ip_address
}

output "external_ip" {
  description = "Публичный IP-адрес ВМ (null, если nat = false)"
  value       = try(yandex_compute_instance.this.network_interface[0].nat_ip_address, null)
}

output "boot_disk_id" {
  description = "ID загрузочного диска"
  value       = yandex_compute_instance.this.boot_disk[0].disk_id
}

output "attached_disk_id" {
  description = "ID подключаемого диска данных"
  value       = yandex_compute_disk.data.id
}
