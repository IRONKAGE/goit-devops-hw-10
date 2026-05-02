variable "project_name" {
  type        = string
  description = "Назва проєкту"
}

variable "environment" {
  type        = string
  description = "Середовище (dev, prod)"
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "ID VPC для Security Group"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR блок VPC для дозволу доступу"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Список ID приватних підмереж"
}

variable "use_aurora" {
  type        = bool
  description = "Створювати Aurora Cluster (true) чи звичайний RDS (false)"
}

variable "engine" {
  type        = string
  description = "Тип рушія БД (postgres, mysql, aurora-postgresql, aurora-mysql)"

  # Валідація вхідних даних
  validation {
    condition     = contains(["postgres", "mysql", "aurora-postgresql", "aurora-mysql"], var.engine)
    error_message = "Дозволені значення для engine: postgres, mysql, aurora-postgresql, aurora-mysql."
  }
}

variable "engine_version" {
  type        = string
  description = "Версія рушія бази даних Aurora PostgreSQL"
  default     = "18.0"
}

variable "db_parameter_group_family" {
  type        = string
  description = "Родина параметрів (напр. postgres14, aurora-postgresql14)"
}

variable "instance_class" {
  type        = string
  description = "Клас інстансу (напр. db.t3.micro)"
}

variable "db_port" {
  type        = number
  description = "Порт підключення до БД"
}

variable "multi_az" {
  type        = bool
  description = "Ввімкнути Multi-AZ для RDS"
  default     = false
}
