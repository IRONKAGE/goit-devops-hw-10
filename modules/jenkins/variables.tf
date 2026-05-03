variable "namespace" {
  description = "Namespace для Jenkins"
  type        = string
}

variable "jenkins_admin_password" {
  description = "Пароль адміністратора Jenkins"
  type        = string
  sensitive   = true
}
