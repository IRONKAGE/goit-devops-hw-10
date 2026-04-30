resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = true
  version          = "6.7.11"

  set = [{
    name  = "server.insecure"
    value = "true"
  }]
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  chart      = "${path.module}/charts"
  namespace  = var.namespace
  depends_on = [helm_release.argocd]

  set = [{
    name  = "githubRepo"
    value = var.github_repo
  }]
}
