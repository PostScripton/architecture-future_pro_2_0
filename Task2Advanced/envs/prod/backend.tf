terraform {
  # Состояние хранится в S3-совместимом Yandex Object Storage.
  # Параметры бакета (bucket, key, region, endpoints) задаются частично
  # через файл <env>.s3.tfbackend, ключи доступа - через переменные
  # окружения AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY.
  # Локальный terraform.tfstate не используется.
  backend "s3" {}
}
