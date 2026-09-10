# Каталог доменных событий

Основные события целевой событийной архитектуры "Будущее 2.0". Для каждого события указаны контекст-источник, семантика (когда публикуется), минимальный контракт полезной нагрузки и подписчики.

## Общий конверт события

Все события используют единый конверт (формат в стиле CloudEvents), схемы хранятся в реестре схем (Avro или JSON Schema):

- `eventId` - UUID события, ключ идемпотентности для потребителя.
- `eventType` - тип, вид `<context>.<aggregate>.<action>`, например `lending.credit-contract.created`.
- `eventVersion` - версия схемы, semver; несовместимое изменение - новый major и новый топик.
- `occurredAt` - время наступления факта, RFC 3339, UTC.
- `producer` - контекст-источник.
- `partitionKey` - идентификатор агрегата; гарантирует порядок событий в пределах одного агрегата.
- `subject` - ссылка на агрегат (тип и идентификатор).
- `correlationId`, `causationId` - трассировка бизнес-цепочки (сага, процесс).
- `data` - полезная нагрузка, описана ниже для каждого события.

Гарантии: доставка at-least-once, потребители обязаны быть идемпотентными по `eventId`; порядок - только в пределах `partitionKey`; необработанные сообщения уходят в DLQ контекста-источника.

Соглашение по PII: события не переносят медицинские карты, истории болезни и полные результаты исследований. В нагрузке - идентификаторы, статусы, суммы, ссылки. Чувствительные поля маскируются или заменяются ссылкой на защищённое хранилище.

## Идентификация клиента и MDM

### CustomerRegistered

- Контекст-источник: Идентификация клиента и MDM.
- Семантика: создан новый мастер-профиль клиента.
- `data`: `customerId`, `partyType` (individual или organization), `createdAt`, `sourceSystem`.
- Подписчики: Пациентский поток, Кредитование, Платежи и счета, Медицинский биллинг, Витрина данных.

### CustomerIdentitiesLinked

- Контекст-источник: Идентификация клиента и MDM.
- Семантика: к мастер-профилю привязан внешний идентификатор либо слиты два профиля.
- `data`: `customerId`, `linkedIdentifiers` (список: `system`, `externalId`), `mergedFrom` (опционально), `linkedAt`.
- Подписчики: все контексты, работающие с клиентом; Витрина данных; Корпоративная финансовая консолидация.

## Пациентский поток

### PatientRegistered

- Контекст-источник: Пациентский поток.
- Семантика: пациент зарегистрирован в клинике.
- `data`: `patientId`, `customerId`, `clinicId`, `registeredAt`, `consentIds`.
- Подписчики: Идентификация клиента и MDM, Согласия и комплаенс-аудит, Витрина данных, Уведомления.

### AppointmentScheduled

- Контекст-источник: Пациентский поток.
- Семантика: создана и подтверждена запись на приём.
- `data`: `appointmentId`, `patientId`, `customerId`, `clinicId`, `practitionerId`, `serviceCode`, `slotStart`, `slotEnd`.
- Подписчики: Уведомления, Инвентаризация и оборудование (планирование загрузки), Витрина данных.

### AiStudyRequested

- Контекст-источник: Пациентский поток.
- Семантика: врач назначил ИИ-исследование в рамках визита.
- `data`: `orderId`, `encounterId`, `patientId`, `studyType`, `requestedBy`, `requestedAt`, `datasetRef`.
- Подписчики: ИИ-диагностика, Витрина данных.

### EncounterCompleted

- Контекст-источник: Пациентский поток.
- Семантика: визит закрыт, зафиксирован перечень оказанных услуг.
- `data`: `encounterId`, `patientId`, `customerId`, `clinicId`, `practitionerId`, `services` (список: `serviceCode`, `quantity`), `completedAt`.
- Подписчики: Медицинский биллинг, Корпоративная финансовая консолидация, Витрина данных.

## ИИ-диагностика

### AiStudyCompleted

- Контекст-источник: ИИ-диагностика.
- Семантика: прогон ИИ-модели по исследованию успешно завершён.
- `data`: `studyId`, `orderId`, `encounterId`, `patientId`, `studyType`, `modelVersion`, `completedAt`, `qualityScore`.
- Подписчики: Медицинский биллинг (основание для начисления), Пациентский поток, Витрина данных.

### AiReportIssued

- Контекст-источник: ИИ-диагностика.
- Семантика: по пройденному исследованию сформировано заключение.
- `data`: `reportId`, `studyId`, `patientId`, `confidenceLevel`, `requiresPhysicianReview` (bool), `issuedAt`, `reportRef`.
- Подписчики: Пациентский поток, Уведомления, Согласия и комплаенс-аудит.

## Медицинский биллинг

### MedicalInvoiceIssued

- Контекст-источник: Медицинский биллинг.
- Семантика: счёт за медицинские услуги выставлен клиенту.
- `data`: `invoiceId`, `customerId`, `encounterId`, `currency`, `totalAmount`, `lineItems` (список: `serviceCode`, `quantity`, `unitPrice`), `issuedAt`, `dueDate`.
- Подписчики: Кредитование (предложение рассрочки), Платежи и счета, Корпоративная финансовая консолидация, Витрина данных, Уведомления.

### InvoicePaid

- Контекст-источник: Медицинский биллинг.
- Семантика: счёт полностью оплачен.
- `data`: `invoiceId`, `customerId`, `paidAmount`, `currency`, `paidAt`, `paymentIds`.
- Подписчики: Корпоративная финансовая консолидация, Витрина данных, Уведомления.

## Кредитование

### LoanApplicationSubmitted

- Контекст-источник: Кредитование.
- Семантика: клиент подал заявку на кредит или рассрочку.
- `data`: `loanApplicationId`, `customerId`, `requestedAmount`, `currency`, `termMonths`, `purpose`, `linkedInvoiceId` (опционально), `submittedAt`.
- Подписчики: Согласия и комплаенс-аудит, Витрина данных.

### CreditContractCreated

- Контекст-источник: Кредитование.
- Семантика: по одобренной заявке оформлен кредитный договор.
- `data`: `creditContractId`, `loanApplicationId`, `customerId`, `principalAmount`, `currency`, `interestRate`, `termMonths`, `schedule` (список: `installmentNo`, `dueDate`, `amount`), `createdAt`.
- Подписчики: Платежи и счета (график списаний), Корпоративная финансовая консолидация, Согласия и комплаенс-аудит, Витрина данных, Уведомления.

### LoanRepaymentProcessed

- Контекст-источник: Кредитование.
- Семантика: учтён очередной платёж по кредиту, обновлён остаток задолженности.
- `data`: `creditContractId`, `customerId`, `installmentNo`, `paidAmount`, `currency`, `outstandingBalance`, `processedAt`, `paymentId`.
- Подписчики: Корпоративная финансовая консолидация, Витрина данных, Потоковые витрины.

### LoanClosed

- Контекст-источник: Кредитование.
- Семантика: задолженность по договору полностью погашена, договор закрыт.
- `data`: `creditContractId`, `customerId`, `closedAt`, `closingReason` (repaid или early-repaid).
- Подписчики: Корпоративная финансовая консолидация, Витрина данных, Уведомления.

## Платежи и счета

### AccountOpened

- Контекст-источник: Платежи и счета.
- Семантика: клиенту открыт расчётный счёт.
- `data`: `accountId`, `customerId`, `accountNumber`, `currency`, `openedAt`.
- Подписчики: Кредитование, Корпоративная финансовая консолидация, Витрина данных.

### PaymentCaptured

- Контекст-источник: Платежи и счета.
- Семантика: платёж успешно проведён и списан со счёта-источника.
- `data`: `paymentId`, `customerId`, `sourceAccountId`, `amount`, `currency`, `target` (`type`: invoice или loan, `id`), `operationKey`, `capturedAt`.
- Подписчики: Медицинский биллинг, Кредитование, Корпоративная финансовая консолидация, Потоковые витрины, Витрина данных.

## Управление персоналом

### EmployeeHired

- Контекст-источник: Управление персоналом.
- Семантика: принят новый сотрудник.
- `data`: `employeeId`, `personnelNumber`, `orgUnitId`, `position`, `hiredAt`.
- Подписчики: Управление доступом (IAM), Витрина данных, Корпоративная финансовая консолидация.

### EmployeeAssignmentChanged

- Контекст-источник: Управление персоналом.
- Семантика: изменено назначение сотрудника (подразделение, должность, ставка, роль).
- `data`: `employeeId`, `previousAssignment`, `newAssignment` (`orgUnitId`, `position`, `role`, `rate`, `validFrom`), `changedAt`.
- Подписчики: Управление доступом (IAM), Витрина данных.

## Инвентаризация и оборудование

### EquipmentReceived

- Контекст-источник: Инвентаризация и оборудование.
- Семантика: единица оборудования поставлена и поставлена на учёт.
- `data`: `equipmentUnitId`, `equipmentType`, `serialNumber`, `clinicId`, `receivedAt`, `partnerShipmentId` (опционально).
- Подписчики: Витрина данных, Корпоративная финансовая консолидация.

### StockLevelBelowThreshold

- Контекст-источник: Инвентаризация и оборудование.
- Семантика: остаток по позиции запаса опустился ниже минимального порога.
- `data`: `stockItemId`, `sku`, `warehouseId`, `currentQuantity`, `threshold`, `detectedAt`.
- Подписчики: Партнёрская интеграция (заказ поставки), Уведомления, Витрина данных.

## Партнёрская интеграция

### PartnerShipmentRegistered

- Контекст-источник: Партнёрская интеграция.
- Семантика: зарегистрирована поставка от внешнего партнёра (нормализована из API партнёра через ACL).
- `data`: `partnerShipmentId`, `partnerId`, `partnerReference`, `items` (список: `kind` drug или equipment, `code`, `quantity`, `batch`, `expiryDate`), `registeredAt`.
- Подписчики: Инвентаризация и оборудование, Витрина данных.

### DrugCatalogUpdated

- Контекст-источник: Партнёрская интеграция.
- Семантика: обновлён каталог препаратов партнёра (новая версия записи).
- `data`: `drugCatalogItemId`, `partnerId`, `drugCode`, `name`, `form`, `version`, `updatedAt`.
- Подписчики: ИИ-диагностика, Медицинский биллинг, Витрина данных.

## Согласия и комплаенс-аудит

### ConsentUpdated

- Контекст-источник: Согласия и комплаенс-аудит.
- Семантика: согласие клиента на обработку данных выдано, изменено или отозвано.
- `data`: `consentId`, `customerId`, `purpose`, `dataScopes`, `status` (granted, revoked, expired), `effectiveFrom`, `effectiveTo`, `updatedAt`.
- Подписчики: Пациентский поток, ИИ-диагностика, Кредитование, Витрина данных, Управление доступом (IAM).

### DataAccessAudited

- Контекст-источник: Согласия и комплаенс-аудит.
- Семантика: зафиксировано решение по доступу к чувствительным данным (для отчётности регуляторам).
- `data`: `auditRecordId`, `subjectId`, `resource`, `action`, `decision` (allow или deny), `policyId`, `occurredAt`.
- Подписчики: Витрина данных (ограниченный доступ), Корпоративная финансовая консолидация не подписывается.

## Корпоративная финансовая консолидация

### ConsolidationPeriodClosed

- Контекст-источник: Корпоративная финансовая консолидация.
- Семантика: консолидационный период закрыт, итоговые показатели зафиксированы.
- `data`: `consolidationPeriodId`, `period`, `businessLines`, `totals`, `closedAt`.
- Подписчики: Витрина данных, Уведомления.

## Витрина данных и дата-продукты

### DataProductPublished

- Контекст-источник: Витрина данных и дата-продукты (публикует домен-владелец).
- Семантика: опубликована новая версия доменного дата-продукта.
- `data`: `dataProductId`, `ownerDomain`, `version`, `contractRef`, `sourceEventTypes`, `publishedAt`.
- Подписчики: Витрина данных (каталог), подписчики конкретного дата-продукта, Согласия и комплаенс-аудит.

## Сводная матрица источников и подписчиков

- Пациентский поток: источник PatientRegistered, AppointmentScheduled, AiStudyRequested, EncounterCompleted; подписчик на AiStudyCompleted, AiReportIssued, ConsentUpdated, CustomerRegistered.
- ИИ-диагностика: источник AiStudyCompleted, AiReportIssued; подписчик на AiStudyRequested, DrugCatalogUpdated, ConsentUpdated.
- Медицинский биллинг: источник MedicalInvoiceIssued, InvoicePaid; подписчик на EncounterCompleted, AiStudyCompleted, PaymentCaptured, DrugCatalogUpdated.
- Кредитование: источник LoanApplicationSubmitted, CreditContractCreated, LoanRepaymentProcessed, LoanClosed; подписчик на MedicalInvoiceIssued, PaymentCaptured, ConsentUpdated, AccountOpened.
- Платежи и счета: источник AccountOpened, PaymentCaptured; подписчик на CreditContractCreated, MedicalInvoiceIssued.
- Идентификация клиента и MDM: источник CustomerRegistered, CustomerIdentitiesLinked; подписчик на PatientRegistered.
- Управление персоналом: источник EmployeeHired, EmployeeAssignmentChanged.
- Инвентаризация и оборудование: источник EquipmentReceived, StockLevelBelowThreshold; подписчик на PartnerShipmentRegistered, AppointmentScheduled.
- Партнёрская интеграция: источник PartnerShipmentRegistered, DrugCatalogUpdated; подписчик на StockLevelBelowThreshold.
- Согласия и комплаенс-аудит: источник ConsentUpdated, DataAccessAudited; подписчик на PatientRegistered, AiReportIssued, LoanApplicationSubmitted, CreditContractCreated.
- Корпоративная финансовая консолидация: источник ConsolidationPeriodClosed; подписчик на EncounterCompleted, MedicalInvoiceIssued, InvoicePaid, CreditContractCreated, LoanRepaymentProcessed, LoanClosed, PaymentCaptured, AccountOpened, EquipmentReceived, EmployeeHired.
- Витрина данных и дата-продукты: источник DataProductPublished; подписчик на все события, кроме медицинского контента.
- Управление доступом (IAM): подписчик на EmployeeHired, EmployeeAssignmentChanged, ConsentUpdated.
- Уведомления: подписчик на AppointmentScheduled, AiReportIssued, MedicalInvoiceIssued, InvoicePaid, CreditContractCreated, LoanClosed, StockLevelBelowThreshold, ConsolidationPeriodClosed.
