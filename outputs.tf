output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_url" {
  description = "URL ECR репозиторію для Makefile"
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "Виводимо тільки якщо модуль EKS увімкнений"
  value = length(module.eks) > 0 ? module.eks[0].cluster_name : "EKS is disabled"
}

output "update_kubeconfig_command" {
  description = "Команда для налаштування доступу до кластера"
  value       = length(module.eks) > 0 ? "aws eks update-kubeconfig --region ${var.region} --name ${module.eks[0].cluster_name}" : "EKS disabled"
}

output "db_endpoint" {
  description = "URL для підключення до бази даних"
  value       = module.rds.db_endpoint
}

output "db_password" {
  description = "Пароль адміністратора БД"
  value       = module.rds.db_password
  sensitive   = true
}
