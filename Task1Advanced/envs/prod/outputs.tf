output "instance_id" {
  description = "ID виртуальной машины"
  value       = module.vm.instance_id
}

output "instance_name" {
  description = "Имя виртуальной машины"
  value       = module.vm.instance_name
}

output "fqdn" {
  description = "FQDN виртуальной машины"
  value       = module.vm.fqdn
}

output "internal_ip" {
  description = "Внутренний IP-адрес"
  value       = module.vm.internal_ip
}

output "external_ip" {
  description = "Публичный IP-адрес"
  value       = module.vm.external_ip
}

output "boot_disk_id" {
  description = "ID загрузочного диска"
  value       = module.vm.boot_disk_id
}

output "attached_disk_id" {
  description = "ID подключаемого диска"
  value       = module.vm.attached_disk_id
}
