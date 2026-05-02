# 1. Роль для Service Account (використовуємо OIDC модуль)
module "irsa_ebs_csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  # Створюється тільки в AWS (Prod)
  count = var.environment == "prod" ? 1 : 0
  role_name             = "${var.cluster_name}-ebs-csi-role"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# 2. Встановлення Add-on для EKS (EBS CSI Driver)
resource "aws_eks_addon" "ebs_csi" {
  # Встановлюємо тільки в AWS
  count = var.environment == "prod" ? 1 : 0

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"

  # Звертаємось до модуля через індекс [0], оскільки ми додали count
  service_account_role_arn = module.irsa_ebs_csi[0].iam_role_arn
  # Прибрав hardcoded addon_version, тому що AWS сам підбере найстабільнішу версію під твій кластер!
}
