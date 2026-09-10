# Задание 1. Модульная инфраструктура для нескольких сред

Переиспользуемый модуль Terraform для создания виртуальной машины в Yandex Cloud и три окружения (dev, stage, prod), которые вызывают один и тот же модуль с разными параметрами через `-var-file`.

## Структура

```
Task1Advanced/
├── modules/
│   └── vm/
│       ├── main.tf        # ВМ + подключаемый диск данных + сетевой интерфейс
│       ├── variables.tf   # входные параметры модуля
│       └── outputs.tf     # выходные значения
└── envs/
    ├── dev/   (main.tf, variables.tf, outputs.tf, dev.tfvars)
    ├── stage/ (main.tf, variables.tf, outputs.tf, stage.tfvars)
    └── prod/  (main.tf, variables.tf, outputs.tf, prod.tfvars)
```

Файлы `main.tf`, `variables.tf`, `outputs.tf` во всех трёх окружениях одинаковые - меняется только `*.tfvars`. Внутри модуля нет захардкоженных значений окружений, всё приходит через переменные.

- [modules/vm/main.tf](modules/vm/main.tf)
- [modules/vm/variables.tf](modules/vm/variables.tf)
- [modules/vm/outputs.tf](modules/vm/outputs.tf)
- [envs/dev/dev.tfvars](envs/dev/dev.tfvars)
- [envs/stage/stage.tfvars](envs/stage/stage.tfvars)
- [envs/prod/prod.tfvars](envs/prod/prod.tfvars)

## Что делает модуль

`modules/vm` создаёт:

- `yandex_compute_instance` - виртуальную машину с заданным числом ядер, объёмом RAM и долей vCPU, загрузочным диском из образа, сетевым интерфейсом в указанной подсети и SSH-ключом в метаданных;
- `yandex_compute_disk` - отдельный подключаемый (вторичный) диск данных, который присоединяется к ВМ через блок `secondary_disk` с `auto_delete = false`.

## Параметры модуля

Обязательные (по интерфейсу задания):

- `cores` - количество ядер (vCPU);
- `memory` - объём RAM в ГБ;
- `attached_disk_size` - размер подключаемого диска в ГБ (тип - `attached_disk_type`);
- `subnet_id` - ID подсети для сетевого интерфейса;
- `ssh_key` - содержимое публичного SSH-ключа;
- `name` - имя ВМ и производных ресурсов;
- `image_id` - ID образа загрузочного диска.

Необязательные (со значениями по умолчанию):

- `zone` - зона доступности, по умолчанию `ru-central1-a`;
- `core_fraction` - гарантированная доля vCPU (100, 50, 20, 5), по умолчанию 100;
- `nat` - выдавать ли публичный IP, по умолчанию `false`;
- `ssh_user` - пользователь ОС для SSH-ключа, по умолчанию `ubuntu`;
- `boot_disk_size` - размер загрузочного диска в ГБ, по умолчанию 20;
- `boot_disk_type` - тип загрузочного диска, по умолчанию `network-hdd`;
- `attached_disk_type` - тип подключаемого диска, по умолчанию `network-ssd`;
- `preemptible` - создавать прерываемую ВМ, по умолчанию `false`;
- `labels` - метки ресурсов, по умолчанию пустая карта.

## Выходы модуля

- `instance_id` - ID виртуальной машины;
- `instance_name` - имя виртуальной машины;
- `fqdn` - FQDN виртуальной машины;
- `internal_ip` - внутренний IP-адрес;
- `external_ip` - публичный IP-адрес (`null`, если `nat = false`);
- `boot_disk_id` - ID загрузочного диска;
- `attached_disk_id` - ID подключаемого диска данных.

Те же значения проброшены наружу в `outputs.tf` каждого окружения.

## Различия окружений

- dev: 2 ядра, 2 ГБ RAM, `core_fraction = 20`, прерываемая ВМ, публичный IP, диски `network-hdd` по 20 ГБ. Минимальная стоимость.
- stage: 4 ядра, 8 ГБ RAM, `core_fraction = 100`, без публичного IP, диски `network-ssd` (30 и 100 ГБ), зона `ru-central1-b`.
- prod: 8 ядер, 32 ГБ RAM, `core_fraction = 100`, без публичного IP, диски `network-ssd` (50 и 500 ГБ).

## Как запустить

Требуется Terraform >= 1.5 и настроенная аутентификация в Yandex Cloud (переменная окружения `YC_TOKEN` или `yc` CLI / сервисный аккаунт).

В файлах `*.tfvars` значения `cloud_id`, `folder_id`, `subnet_id`, `image_id` и `ssh_key` - примеры, их нужно заменить на реальные для своей инфраструктуры.

dev:

```
cd envs/dev
terraform init
terraform plan  -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

stage:

```
cd envs/stage
terraform init
terraform apply -var-file=stage.tfvars
```

prod:

```
cd envs/prod
terraform init
terraform apply -var-file=prod.tfvars
```

## Проверка

- `terraform fmt -recursive -check` - код отформатирован;
- `terraform validate` в `modules/vm` и в каждом окружении `envs/*` - конфигурация валидна.
