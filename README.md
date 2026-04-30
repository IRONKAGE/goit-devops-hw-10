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
2. Архів проєкту `lesson-db-module_<ПІБ>.zip`, прикріплений в `LMS`
3. Повністю готовий до запуску **Terraform-код**

>❗️ ⚠️ УВАГА! ⚠️ При роботі з хмарними провайдерами завжди пам'ятайте: невикористані ресурси можуть призвести до значних витрат. Щоб уникнути непередбачуваних рахунків, після перевірки вашого коду обов'язково видаляйте створені ресурси. Використовуйте команду terraform destroy.

>❗️ ⚠️ УВАГА! ⚠️ Пам'ятайте порядок запуску інфраструктури після видалення! При видаленні всієї інфраструктури за допомогою terraform destroy ви також видаляєте S3-бакет і DynamoDB-таблицю, які використовуються для збереження Terraform стейту.
