resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  namespace        = var.namespace
  create_namespace = true

  replace          = true
  cleanup_on_fail  = true
  timeout          = 600

  wait             = true

  values = [
    file("${path.module}/values.yaml")
  ]

  # 1. Передаємо логін (змінна з .env)
  set {
    name  = "controller.admin.username"
    value = var.jenkins_admin_username
  }

  # 2. Пароль приховано (змінна з .env)
  set_sensitive {
    name  = "controller.admin.password"
    value = var.jenkins_admin_password
  }

  # 3. Збільшуємо ліміт терпіння Kubernetes (60 спроб по 10 сек = 10 хвилин)
  set {
    name  = "controller.probes.startupProbe.failureThreshold"
    value = "60"
  }
}
