variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID каталога Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-a"
}

variable "state_bucket_name" {
  description = "Имя бакета для удалённого состояния Terraform (глобально уникальное)"
  type        = string
  default     = "future20-tfstate"
}
