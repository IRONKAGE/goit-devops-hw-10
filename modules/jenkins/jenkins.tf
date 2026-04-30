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

  set = [
    {
      name  = "controller.admin.password"
      value = "admin_password_123"
    },
    {
      name  = "persistence.enabled"
      value = "false"
    },
    {
      # Збільшуємо ліміт терпіння Kubernetes (60 спроб по 10 сек = 10 хвилин)
      name  = "controller.probes.startupProbe.failureThreshold"
      value = "60"
    }
  ]
}
