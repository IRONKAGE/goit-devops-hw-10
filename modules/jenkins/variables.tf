variable "namespace" {
  description = "Namespace для Jenkins"
  type        = string
}

variable "jenkins_admin_username" {
  description = "Логін адміністратора Jenkins"
  type        = string
  default     = "admin" # Запасний варіант, якщо забули додати у .env
}

variable "jenkins_admin_password" {
  description = "Пароль адміністратора Jenkins"
  type        = string
  sensitive   = true
}
