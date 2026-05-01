# goit-devops-hw-10

***Технiчний опис завдань***

# **Завдання 10: Адміністрування баз даних**

## **Опис завдання:**

Цього разу ви створите **продакшн-готовий Terraform-модуль**, який може створювати:

- Звичайну RDS-базу (PostgreSQL / MySQL)
- **Або Aurora-кластер**, залежно від прапора `use_aurora = true`

*Це завдання навчить вас працювати з умовною логікою в `Terraform`, залежностями між ресурсами та структурованими змінними.*

## **Кроки виконання завдання:**

Реалізувати універсальний модуль rds, який:

1. **Підіймає**:
   - `Aurora Cluster`
   - Або звичайну `RDS instance` на основі значення `use_aurora`

2. **Автоматично створює**:
   - **DB Subnet Group**
   - **Security Group**
   - **Parameter Group для обраного типу БД**

3. **Працює**:
   - З мінімальними змінами змінних
   - Підтримує багаторазове використання

**Структура проекту:**

```md
goit-devops-hw-10/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB
├── outputs.tf               # Загальні виводи ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf           # Створення ECR репозиторію
│   │   ├── variables.tf     # Змінні для ECR
│   │   └── outputs.tf       # Виведення URL репозиторію
│   │
│   ├── eks/                      # Модуль для Kubernetes кластера
│   │   ├── eks.tf                # Створення кластера
│   │   ├── aws_ebs_csi_driver.tf # Встановлення плагіну csi drive
│   │   ├── variables.tf     # Змінні для EKS
│   │   └── outputs.tf       # Виведення інформації про кластер
│   │
│   ├── rds/                 # Модуль для RDS
│   │   ├── rds.tf           # Створення RDS бази даних
│   │   ├── aurora.tf        # Створення aurora кластера бази даних
│   │   ├── shared.tf        # Спільні ресурси
│   │   ├── variables.tf     # Змінні (ресурси, креденшели, values)
│   │   └── outputs.tf
│   │
│   ├── jenkins/             # Модуль для Helm-установки Jenkins
│   │   ├── jenkins.tf       # Helm release для Jenkins
│   │   ├── variables.tf     # Змінні (ресурси, креденшели, values)
│   │   ├── providers.tf     # Оголошення провайдерів
│   │   ├── values.yaml      # Конфігурація jenkins
│   │   └── outputs.tf       # Виводи (URL, пароль адміністратора)
│   │
│   └── argo_cd/             # ✅ Новий модуль для Helm-установки Argo CD
│       ├── jenkins.tf       # Helm release для Jenkins
│       ├── variables.tf     # Змінні (версія чарта, namespace, repo URL тощо)
│       ├── providers.tf     # Kubernetes+Helm.  переносимо з модуля jenkins
│       ├── values.yaml      # Кастомна конфігурація Argo CD
│       ├── outputs.tf       # Виводи (hostname, initial admin password)
│		    └──charts/                  # Helm-чарт для створення app'ів
│ 	 	    ├── Chart.yaml
│	  	    ├── values.yaml          # Список applications, repositories
│			    └── templates/
│		        ├── application.yaml
│		        └── repository.yaml
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── hpa.yaml
│       ├── Chart.yaml
│       └── values.yaml     # ConfigMap зі змінними середовища
```

**Функціонал модуля:**

- `use_aurora = true` → створюється `Aurora Cluster` + `writer`
- `use_aurora = false` → створюється одна `aws_db_instance`
- В обох випадках:
   - Створюється `aws_db_subnet_group`
   - Створюється `aws_security_group`
   - Створюється `parameter group` з базовими параметрами (`max_connections`, `log_statement`, `work_mem`);
- Параметри `engine`, `engine_version`, `instance_class`, `multi_az` задаються через змінні

**README.md повинен містити:**

1. Приклад використання модуля (`module` "rds" { ... })
2. Опис усіх змінних із поясненням
3. Опис того, як змінити тип БД, engine, клас інстансу тощо

**Формат здачі:**

1. Посилання на `GitHub`-репозиторій, гілка `lesson-db-module`
2. Архів проекту `lesson-db-module_<ПІБ>.zip`, прикріплений в `LMS`
3. Повністю готовий до запуску **Terraform-код**

>❗️ ⚠️ УВАГА! ⚠️ При роботі з хмарними провайдерами завжди пам'ятайте: невикористані ресурси можуть призвести до значних витрат. Щоб уникнути непередбачуваних рахунків, після перевірки вашого коду обов'язково видаляйте створені ресурси. Використовуйте команду terraform destroy.

>❗️ ⚠️ УВАГА! ⚠️ Пам'ятайте порядок запуску інфраструктури після видалення! При видаленні всієї інфраструктури за допомогою terraform destroy ви також видаляєте S3-бакет і DynamoDB-таблицю, які використовуються для збереження Terraform стейту.

---

## AWS RDS & Aurora Universal Terraform Module

Цей репозиторій містить універсальний `production-ready` модуль Terraform для розгортання баз даних в AWS. Модуль підтримує створення як звичайних інстансів **Amazon RDS** (PostgreSQL/MySQL), так і кластерів **Amazon Aurora**.

### 🌟 Особливості

- **Динамічне розгортання:** Вибір між RDS та Aurora здійснюється зміною лише одного прапорця `use_aurora`.
- **DRY & Надійність:** Використання `locals` для уніфікованого неймінгу та тегування. Вбудована валідація змінних (наприклад, блокування неправильних типів `engine`).
- **Secure by Default:** Пароль адміністратора генерується автоматично через провайдер `random_password` і зберігається у state-файлі (не передається у відкритому вигляді через змінні).
- **Мережева ізоляція:** База даних розгортається у приватних підмережах (DB Subnet Group), а Security Group дозволяє доступ лише зсередини вказаної VPC.
- **Автоматизація залежностей:** Модуль сам створює відповідні Parameter Groups залежно від типу обраної бази даних (Cluster PG для Aurora або DB PG для RDS).
- **Безпечні Outputs:** Використання функції `try()` гарантує відсутність помилок при виведенні Endpoint незалежно від обраного типу бази.

---

### 🚀 1. Приклад використання модуля RDS

Частина коду з `main.tf` для виклику модуля:

```hcl
module "rds" {
  source = "./modules/rds"

  # Базові налаштування
  project_name       = var.project_name
  environment        = var.environment

  # Мережа (отримуємо з модуля VPC)
  vpc_id             = module.vpc.vpc_id
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  private_subnet_ids = module.vpc.private_subnet_ids

  # ===================================================
  # ГОЛОВНИЙ ПЕРЕМИКАЧ: true для Aurora, false для RDS
  # ===================================================
  use_aurora         = false

  # Параметри БД
  engine                    = "postgres"
  engine_version            = "18"
  db_parameter_group_family = "postgres18"
  instance_class            = "db.t3.micro"
  db_port                   = 5432
  multi_az                  = false
}
```

---

### ⚙️ 2. Опис змінних модуля (Variables)

| Назва змінної | Тип | Опис | Обов'язкова |
|---------------|------|------|:---:|
| `use_aurora` | `bool` | Перемикач типу БД. Якщо `true` — створюється Aurora Cluster, якщо `false` — класичний RDS Instance. | ✅ Так |
| `project_name` | `string` | Назва проекту для тегування та неймінгу ресурсів. | ✅ Так |
| `environment` | `string` | Середовище розгортання (dev, prod, stage). | ✅ Так |
| `vpc_id` | `string` | ID існуючої VPC, де буде створена Security Group для БД. | ✅ Так |
| `vpc_cidr_block` | `string` | CIDR блок вашої VPC для налаштування Ingress правил (доступ тільки зсередини). | ✅ Так |
| `private_subnet_ids`| `list(string)`| Список ID приватних підмереж для створення DB Subnet Group. | ✅ Так |
| `engine` | `string` | Тип рушія БД. Дозволені значення: `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql`. | ✅ Так |
| `engine_version` | `string` | Версія рушія бази даних (напр., `18.0`, `9.7`). | ✅ Так |
| `db_parameter_group_family` | `string` | Родина параметрів для Parameter Group (напр., `postgres14`, `aurora-postgresql14`). | ✅ Так |
| `instance_class` | `string` | Клас інстансу бази даних (напр., `db.t3.micro`, `db.r5.large`). | ✅ Так |
| `db_port` | `number` | Порт для підключення до БД (5432 для PostgreSQL, 3306 для MySQL). | ✅ Так |
| `multi_az` | `bool` | Ввімкнути резервування у кількох зонах доступності (для звичайного RDS). За замовчуванням `false`. | Ні |

---

### 🔄 3. Як змінити тип БД (Інструкція)

Модуль спроектовано так, щоб змінювати архітектуру можна було на рівні конфігурації, не торкаючись самого коду модуля.

#### Варіант А: Перемикання з класичного RDS на кластер Aurora

Щоб розгорнути високодоступний кластер Aurora замість звичайного RDS, змініть параметри у виклику модуля на наступні:

- `use_aurora` = `true`
- `engine` = `"aurora-postgresql"` *(або "aurora-mysql")*
- `db_parameter_group_family` = `"aurora-postgresql18"` *(зверніть увагу на префікс aurora-)*
- `instance_class` = `"db.t3.medium"` *(Увага: Aurora не підтримує клас t3.micro)*

#### Варіант Б: Перемикання PostgreSQL на MySQL (для звичайного RDS)

Щоб підняти MySQL інстанс:

1. `use_aurora` = `false`
2. `engine` = `"mysql"`
3. `engine_version` = `"9.7"`
4. `db_parameter_group_family` = `"mysql9.7"`
5. `db_port` = `3306`

---

### 🔑 4. Як отримати доступ до створеної бази

Пароль генерується автоматично і помічений як `sensitive` для безпеки. Він не відображатиметься у стандартному виводі `terraform apply`.

**Щоб отримати URL підключення (Endpoint):**

```bash
terraform output db_endpoint
```

**Щоб отримати згенерований пароль:**

```bash
terraform output -raw db_password
```

---

> ❗️ **УВАГА! ПОПЕРЕДЖЕННЯ ПРО ВИТРАТИ ТА ВИДАЛЕННЯ** ⚠️
> При роботі з хмарними провайдерами завжди пам'ятайте: невикористані ресурси можуть призвести до значних витрат (особливо інстанси Aurora). Щоб уникнути непередбачуваних рахунків, після перевірки вашого коду обов'язково видаляйте створені ресурси.
> Використовуйте команду:
>
> ```bash
> terraform destroy
> ```
>
> *Пам'ятайте порядок запуску інфраструктури після видалення! При видаленні всієї інфраструктури ви також можете видалити S3-бакет і DynamoDB-таблицю бекенду. Модуль налаштований з `skip_final_snapshot = true` для швидкого та безперешкодного видалення БД під час тестування.*
