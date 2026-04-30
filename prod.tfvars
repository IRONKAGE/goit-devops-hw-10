# ==========================================
# Базові налаштування
# ==========================================
# Ця змінна автоматично створить NAT Gateway
environment  = "prod"
region       = "eu-central-1"
project_name = "ironkage-hw89-prod"

# ==========================================
# Мережа - VPC (Multi-AZ)
# ==========================================
# Ширша мережа для великої кількості подів
vpc_cidr             = "10.1.0.0/16"
public_subnets_cidr  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnets_cidr = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
availability_zones   = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

# ==========================================
# Реєстр - ECR
# ==========================================
ecr_repo_name = "django-app-hw89-prod"
# Вмикаємо сканування образів на вразливості при пуші
scan_on_push  = true

# ==========================================
# ОРКЕСТРАЦІЯ - EKS (Production Grade)
# ==========================================
cluster_name    = "ironkage-k8s-hw89-prod"
cluster_version = "1.31"

# Типи інстансів для робочих вузлів (Worker Nodes)
# t3.medium — мінімум для продакшену K8s
# m5.large — рекомендовано для стабільної роботи Django + ML моделей
node_instance_types = ["m5.large"]

# Параметри масштабування (Autoscaling)
node_min_size     = 3
node_max_size     = 10
node_desired_size = 3

# Додатково: вмикаємо логування кластера
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# ==========================================
# GITOPS - ArgoCD
# ==========================================
github_repo = "https://github.com/IRONKAGE/goit-devops-hw-08-09.git"
