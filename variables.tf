variable "environment" { type = string }
variable "region" { type = string }
variable "project_name" { type = string }

variable "vpc_cidr" { type = string }
variable "public_subnets_cidr" { type = list(string) }
variable "private_subnets_cidr" { type = list(string) }
variable "availability_zones" { type = list(string) }

variable "ecr_repo_name" { type = string }
variable "scan_on_push" { type = bool }

variable "cluster_name" { type = string }
variable "cluster_version" { type = string }
variable "node_instance_types" { type = list(string) }
variable "node_min_size" { type = number }
variable "node_max_size" { type = number }
variable "node_desired_size" { type = number }
variable "enabled_cluster_log_types" { type = list(string) }

variable "enable_eks" {
  description = "Вмикає або вимикає розгортання модуля EKS (для обходу LocalStack Pro)"
  type        = bool
  default     = true
}

variable "github_repo" {
  description = "URL GitHub репозиторію для підключення GitOps"
  type        = string
}

variable "localstack_ip" {
  description = "Динамічний IP LocalStack"
  type        = string
  default     = "172.18.0.2"
}

variable "engine_version" {
  description = "Версія рушія бази даних (наприклад, 18 для PostgreSQL або 9.7 для MySQL)"
  type        = string
  default     = "18"
}

variable "jenkins_admin_password" {
  description = "Пароль адміністратора Jenkins"
  type        = string
  sensitive   = true
}
