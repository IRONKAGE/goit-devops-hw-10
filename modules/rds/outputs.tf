output "db_endpoint" {
  description = "URL для підключення до бази даних"
  # Використано try() для уникнення помилок при зміні стейту
  value = try(
    aws_rds_cluster.django_aurora_v2[0].endpoint,
    aws_db_instance.rds[0].endpoint,
    "Базу даних не знайдено"
  )
}

output "db_username" {
  description = "Логін адміністратора БД"
  value       = "adminuser"
}

output "db_password" {
  description = "Пароль адміністратора БД"
  value       = random_password.db_master_pass.result
  sensitive   = true
}

output "db_port" {
  description = "Порт для підключення"
  value       = var.db_port
}
