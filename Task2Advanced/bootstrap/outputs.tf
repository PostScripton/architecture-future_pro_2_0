output "state_bucket_name" {
  description = "Имя созданного бакета для удалённого состояния"
  value       = yandex_storage_bucket.tfstate.bucket
}

output "tfstate_access_key" {
  description = "Access key сервисного аккаунта для backend (в GitHub Secret TFSTATE_ACCESS_KEY)"
  value       = yandex_iam_service_account_static_access_key.tfstate.access_key
  sensitive   = true
}

output "tfstate_secret_key" {
  description = "Secret key сервисного аккаунта для backend (в GitHub Secret TFSTATE_SECRET_KEY)"
  value       = yandex_iam_service_account_static_access_key.tfstate.secret_key
  sensitive   = true
}
