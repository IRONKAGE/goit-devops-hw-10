# ==========================================
# Базові налаштування
# ==========================================
environment  = "dev"          # <-- Запускає логіку вимкнення NAT Gateway
region       = "eu-central-1"
project_name = "ironkage-hw89-dev"

# ==========================================
# Мережа - VPC
# ==========================================
vpc_cidr             = "10.0.0.0/16"
public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets_cidr = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["eu-central-1a", "eu-central-1b"]

# ==========================================
# Реєстр - ECR
# ==========================================
ecr_repo_name = "django-app-hw89-dev"
scan_on_push  = false         # <-- Економимо час при пуші локально

# ==========================================
# ОРКЕСТРАЦІЯ - EKS
# ==========================================
cluster_name    = "ironkage-k8s-hw89-dev"
cluster_version = "1.31"

# Типи та кількість інстансів (Економний режим для розробки)
node_instance_types = ["t3.medium"]
node_min_size       = 1
node_max_size       = 2
node_desired_size   = 1

# Аудит кластера (Вимкнено для dev, щоб економити кошти)
enabled_cluster_log_types = []

# ==========================================
# GITOPS - ArgoCD
# ==========================================
github_repo = "https://github.com/IRONKAGE/goit-devops-hw-08-09.git"
