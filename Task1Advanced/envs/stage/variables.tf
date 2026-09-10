variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID каталога Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-a"
}

variable "name" {
  description = "Имя ВМ"
  type        = string
}

variable "cores" {
  description = "Количество ядер (vCPU)"
  type        = number
}

variable "memory" {
  description = "Объём RAM в ГБ"
  type        = number
}

variable "core_fraction" {
  description = "Гарантированная доля vCPU в процентах"
  type        = number
  default     = 100
}

variable "subnet_id" {
  description = "ID подсети"
  type        = string
}

variable "nat" {
  description = "Выдавать ли публичный IP"
  type        = bool
  default     = false
}

variable "ssh_key" {
  description = "Содержимое публичного SSH-ключа"
  type        = string
}

variable "image_id" {
  description = "ID образа загрузочного диска"
  type        = string
}

variable "boot_disk_size" {
  description = "Размер загрузочного диска в ГБ"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "Тип загрузочного диска"
  type        = string
  default     = "network-hdd"
}

variable "attached_disk_size" {
  description = "Размер подключаемого диска в ГБ"
  type        = number
}

variable "attached_disk_type" {
  description = "Тип подключаемого диска"
  type        = string
  default     = "network-ssd"
}

variable "preemptible" {
  description = "Прерываемая ВМ"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Метки ресурсов"
  type        = map(string)
  default     = {}
}
