variable "name" {
  description = "Имя ВМ и производных ресурсов (диск данных)"
  type        = string
}

variable "zone" {
  description = "Зона доступности, в которой создаются ВМ и диски"
  type        = string
  default     = "ru-central1-a"
}

variable "cores" {
  description = "Количество ядер (vCPU) ВМ"
  type        = number
}

variable "memory" {
  description = "Объём RAM в ГБ"
  type        = number
}

variable "core_fraction" {
  description = "Гарантированная доля vCPU в процентах (100, 50, 20, 5)"
  type        = number
  default     = 100

  validation {
    condition     = contains([100, 50, 20, 5], var.core_fraction)
    error_message = "Допустимые значения core_fraction: 100, 50, 20, 5."
  }
}

variable "subnet_id" {
  description = "ID подсети для сетевого интерфейса ВМ"
  type        = string
}

variable "nat" {
  description = "Выдавать ли ВМ публичный IP-адрес"
  type        = bool
  default     = false
}

variable "ssh_key" {
  description = "Содержимое публичного SSH-ключа для доступа к ВМ"
  type        = string
}

variable "ssh_user" {
  description = "Имя пользователя ОС, которому добавляется SSH-ключ"
  type        = string
  default     = "ubuntu"
}

variable "image_id" {
  description = "ID образа для загрузочного диска"
  type        = string
}

variable "boot_disk_size" {
  description = "Размер загрузочного диска в ГБ"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "Тип загрузочного диска (network-hdd, network-ssd)"
  type        = string
  default     = "network-hdd"
}

variable "attached_disk_size" {
  description = "Размер подключаемого (вторичного) диска в ГБ"
  type        = number
}

variable "attached_disk_type" {
  description = "Тип подключаемого диска (network-hdd, network-ssd, network-ssd-nonreplicated)"
  type        = string
  default     = "network-ssd"
}

variable "preemptible" {
  description = "Создавать прерываемую (preemptible) ВМ"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Метки, назначаемые ВМ и диску данных"
  type        = map(string)
  default     = {}
}
