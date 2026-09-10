terraform {
  required_version = ">= 1.5"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100"
    }
  }

  # Bootstrap выполняется один раз и с локальным состоянием:
  # на этом шаге бакета для удалённого состояния ещё нет.
  # Файл bootstrap/terraform.tfstate после создания бакета
  # можно вручную перенести в этот же бакет (key = bootstrap/terraform.tfstate).
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# Отдельный сервисный аккаунт только для доступа к бакету состояния.
resource "yandex_iam_service_account" "tfstate" {
  name        = "tfstate-backend"
  description = "Доступ Terraform/CI к бакету удалённого состояния"
}

resource "yandex_resourcemanager_folder_iam_member" "tfstate_storage" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.tfstate.id}"
}

resource "yandex_iam_service_account_static_access_key" "tfstate" {
  service_account_id = yandex_iam_service_account.tfstate.id
  description        = "Статический ключ для S3-backend Terraform"
}

resource "yandex_kms_symmetric_key" "tfstate" {
  name              = "tfstate-bucket-key"
  description       = "Ключ шифрования бакета удалённого состояния Terraform"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год
}

resource "yandex_storage_bucket" "tfstate" {
  bucket     = var.state_bucket_name
  access_key = yandex_iam_service_account_static_access_key.tfstate.access_key
  secret_key = yandex_iam_service_account_static_access_key.tfstate.secret_key

  # Бакет строго приватный.
  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  # Версионирование - защита от потери состояния и основа для lock-файла.
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = yandex_kms_symmetric_key.tfstate.id
      }
    }
  }

  lifecycle_rule {
    id      = "expire-noncurrent-state"
    enabled = true

    noncurrent_version_expiration {
      days = 90
    }
  }
}
