variable "cluster_name" {
  description = "Назва EKS кластера"
  type        = string
}

variable "cluster_version" {
  description = "Версія Kubernetes"
  type        = string
}

variable "subnet_ids" {
  description = "Список підмереж для кластера та вузлів"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM Role ARN для Control Plane"
  type        = string
}

variable "node_role_arn" {
  description = "IAM Role ARN для Worker Nodes"
  type        = string
}

variable "node_instance_types" {
  description = "Типи EC2 інстансів для вузлів"
  type        = list(string)
}

variable "node_min_size" {
  description = "Мінімальна кількість вузлів"
  type        = number
}

variable "node_max_size" {
  description = "Максимальна кількість вузлів"
  type        = number
}

variable "node_desired_size" {
  description = "Бажана кількість вузлів"
  type        = number
}

variable "enabled_cluster_log_types" {
  description = "Типи логів для відправки у CloudWatch"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Середовище (dev або prod) для визначення встановлення EBS CSI"
  type        = string
}
