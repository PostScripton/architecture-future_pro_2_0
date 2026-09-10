# Задание 2. Интеграция с CI/CD и удалённым хранением состояния

Terraform-код с удалённым состоянием в S3-совместимом хранилище (Yandex Object Storage) и пайплайн GitHub Actions, который выполняет `terraform init`, `terraform plan` и `terraform apply` с ручным подтверждением (approval) перед применением.

Инфраструктурная часть переиспользует модуль `modules/vm` из [Task1Advanced](../Task1Advanced): создаётся та же ВМ в трёх окружениях. Новое в задании 2 - backend, разбиение секретов и CI/CD-процесс.

## Структура

- [bootstrap/](bootstrap) - разовое создание бакета состояния, KMS-ключа, сервисного аккаунта и статического ключа доступа
- [modules/vm/](modules/vm) - переиспользуемый модуль ВМ (копия модуля из задания 1)
- [envs/dev/](envs/dev), [envs/stage/](envs/stage), [envs/prod/](envs/prod) - три изолированных окружения
- [.github/workflows/terraform.yml](.github/workflows/terraform.yml) - пайплайн CI/CD

В каждом окружении:

- [backend.tf](envs/dev/backend.tf) - блок `backend "s3" {}` без параметров (partial configuration)
- `main.tf`, `variables.tf`, `outputs.tf` - одинаковые во всех трёх окружениях, вызывают `modules/vm`
- `<env>.tfvars` - параметры окружения (размер ВМ, диски, подсеть, метки)
- `<env>.s3.tfbackend` - параметры backend без ключей доступа (bucket, key, region, endpoints)

## Удалённое состояние

Backend объявлен как partial configuration:

```hcl
terraform {
  backend "s3" {}
}
```

Все параметры бакета вынесены в файлы `envs/<env>/<env>.s3.tfbackend` и подставляются флагом `-backend-config`:

```
bucket = "future20-tfstate"
key    = "dev/vm/terraform.tfstate"
region = "ru-central1"
endpoints = { s3 = "https://storage.yandexcloud.net" }

skip_region_validation      = true
skip_credentials_validation = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
skip_s3_checksum            = true
use_lockfile                = true
```

Ключевые моменты:

- Состояние не хранится локально. Файл `terraform.tfstate` в репозиторий не попадает (см. [.gitignore](.gitignore)), в CI каждый прогон идёт на чистом runner'е, состояние читается и пишется только в бакет.
- У каждого окружения свой ключ объекта в бакете (`dev/vm/...`, `stage/vm/...`, `prod/vm/...`) - состояния окружений полностью изолированы в одном бакете.
- `skip_*` нужны потому, что Yandex Object Storage реализует S3 API частично и не отвечает на AWS-специфичные проверки (STS, IMDS, checksum).
- Блокировка состояния - через нативный lock-файл S3 (`use_lockfile = true`, Terraform >= 1.10), отдельная таблица DynamoDB не нужна. Опирается на версионирование бакета, которое включает bootstrap.
- Ключи доступа к бакету (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) в файлах не хранятся, передаются только через переменные окружения из GitHub Secrets.

## Bootstrap

Каталог [bootstrap/](bootstrap) решает проблему "курицы и яйца": бакета для состояния ещё нет, поэтому bootstrap применяется один раз с локальным состоянием.

[bootstrap/main.tf](bootstrap/main.tf) создаёт:

- `yandex_iam_service_account.tfstate` - отдельный сервисный аккаунт только для доступа к бакету состояния (минимальные права);
- `yandex_resourcemanager_folder_iam_member` - роль `storage.editor` на каталог для этого аккаунта;
- `yandex_iam_service_account_static_access_key` - статический ключ (access key + secret key) для S3-backend;
- `yandex_kms_symmetric_key.tfstate` - ключ шифрования бакета с годовой ротацией;
- `yandex_storage_bucket.tfstate` - бакет состояния: приватный (весь анонимный доступ выключен), с версионированием, серверным шифрованием через KMS и правилом удаления неактуальных версий через 90 дней.

Запуск:

```
cd bootstrap
cp bootstrap.tfvars.example bootstrap.tfvars   # подставить cloud_id, folder_id
terraform init
terraform apply -var-file=bootstrap.tfvars
terraform output -raw tfstate_access_key
terraform output -raw tfstate_secret_key
```

Полученные `access_key` и `secret_key` кладутся в GitHub Secrets как `TFSTATE_ACCESS_KEY` и `TFSTATE_SECRET_KEY`.

## Пайплайн CI/CD

Файл [.github/workflows/terraform.yml](.github/workflows/terraform.yml). В рабочем репозитории он должен лежать в корне по пути `.github/workflows/terraform.yml`; здесь размещён внутри `Task2Advanced/` как часть решения.

### Триггеры

- `pull_request` с изменениями в `Task2Advanced/**` - запускается только job `plan` для окружения `dev`. Apply на pull request не выполняется никогда.
- `push` в `master` с изменениями в `Task2Advanced/**` - `plan`, затем `apply` для `dev` после подтверждения.
- `workflow_dispatch` - ручной запуск с выбором окружения (`dev`, `stage`, `prod`) из выпадающего списка. Основной способ выката на stage и prod.

### Job `plan`

1. `actions/checkout` - выгрузка кода.
2. `hashicorp/setup-terraform` с фиксированной версией (`terraform_wrapper: false`, чтобы коды возврата `plan`/`apply` не проглатывались).
3. `terraform fmt -check -recursive` по всему каталогу `Task2Advanced` - падает, если код не отформатирован.
4. `terraform init -input=false -backend-config="<env>.s3.tfbackend"` - инициализация с удалённым backend. Ключи бакета берутся из секретов `TFSTATE_ACCESS_KEY` / `TFSTATE_SECRET_KEY` через переменные окружения `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`.
5. `terraform validate`.
6. `checkov` - статический анализ безопасности Terraform-кода (`soft_fail: true` - не блокирует пайплайн, но выводит замечания).
7. `terraform plan -input=false -lock-timeout=180s -var-file="<env>.tfvars" -out=tfplan` - план сохраняется в файл `tfplan`. Ключ сервисного аккаунта Yandex Cloud пишется из секрета `YC_SA_KEY_JSON` во временный файл `sa-key.json`, путь передаётся через `YC_SERVICE_ACCOUNT_KEY_FILE`, файл удаляется сразу после `plan`.
8. `actions/upload-artifact` - файл `tfplan` сохраняется как артефакт на 5 дней.

### Job `apply`

- Зависит от `plan` (`needs: plan`).
- Условие `if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/master'` - на pull request не запускается.
- `environment: <env>` - привязка к GitHub Environment. Именно здесь настраивается ручное подтверждение: в Settings -> Environments для `dev`, `stage`, `prod` включается "Required reviewers". Пока ревьюер не нажмёт кнопку подтверждения, job `apply` стоит в статусе "Waiting". Это и есть approval-флаг из условия задания.
- Шаги: `checkout`, `setup-terraform`, `terraform init` с тем же backend, `download-artifact` (тот самый `tfplan`), `terraform apply -input=false -lock-timeout=180s -auto-approve tfplan`.
- `apply` применяет сохранённый план `tfplan`, а не считает новый. Между plan и apply инфраструктура измениться не может - применяется ровно то, что видел и подтвердил ревьюер.

### Безопасность и изоляция

- Секреты только в GitHub Secrets, в коде и в `*.tfbackend` их нет. В шагах секреты пробрасываются через блок `env:` шага, а не подставляются в текст команды - это исключает попадание значений в логи и подстановку через содержимое переменных.
- `permissions: contents: read` - токену workflow даётся только чтение репозитория, ничего больше.
- Изоляция окружений: у `dev`, `stage`, `prod` разные `*.tfvars`, разные ключи состояния в бакете и разные GitHub Environments. Секреты (`TFSTATE_ACCESS_KEY`, `TFSTATE_SECRET_KEY`, `YC_SA_KEY_JSON`) можно задать на уровне каждого Environment отдельно - тогда pipeline для `dev` физически не имеет доступа к учётным данным `prod`.
- `concurrency: group: terraform-<env>` с `cancel-in-progress: false` - два прогона на одно окружение не идут параллельно и не конкурируют за один state-файл; вместе с `-lock-timeout` и lock-файлом backend это защищает состояние от гонок.
- Временный файл `sa-key.json` удаляется сразу после использования; в `.gitignore` он тоже добавлен на случай локальных запусков.
- Дефолтное окружение для автоматических триггеров - `dev`; stage и prod выкатываются только осознанным ручным запуском.

## Необходимые GitHub Secrets

- `TFSTATE_ACCESS_KEY` - access key сервисного аккаунта из bootstrap (доступ к бакету состояния)
- `TFSTATE_SECRET_KEY` - secret key оттуда же
- `YC_SA_KEY_JSON` - JSON-ключ сервисного аккаунта Yandex Cloud с правами на создание ВМ и дисков (аутентификация провайдера)

Для полной изоляции эти секреты задаются на уровне каждого Environment (`dev`, `stage`, `prod`), а не репозитория.

## Локальный запуск (эквивалент шагов пайплайна)

```
cd envs/dev

export AWS_ACCESS_KEY_ID=...        # из bootstrap output tfstate_access_key
export AWS_SECRET_ACCESS_KEY=...    # из bootstrap output tfstate_secret_key
export YC_SERVICE_ACCOUNT_KEY_FILE=~/.yc/sa-key.json

terraform init -backend-config=dev.s3.tfbackend
terraform plan  -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```

Значения `cloud_id`, `folder_id`, `subnet_id`, `image_id`, `ssh_key` в `*.tfvars` - примеры, их нужно заменить на реальные.

## Проверка

- `terraform fmt -check -recursive` в каталоге `Task2Advanced` - код отформатирован.
- `terraform validate` в `bootstrap`, `modules/vm` и каждом `envs/*` - конфигурация валидна.
- Пайплайн: на pull request выполняется только `plan`; `apply` доступен после ручного подтверждения в GitHub Environment.
