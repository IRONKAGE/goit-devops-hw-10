resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true # Доступ вузлів до API без інтернету
    endpoint_public_access  = true # Можливість керувати кластером локально
  }

  # Увімкнення логів аудиту для CloudWatch
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # Захист від видалення IAM ролі до видалення кластера
  # depends_on = [
  #   aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  # ]
}

# Приклад конфігурації Node Group (робочих вузлів)
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types

  # Рекомендується використовувати ON_DEMAND для стабільності бази/ML
  capacity_type  = "ON_DEMAND"

  # Захищаємо desired_size від перезапису при наступних terraform apply
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# OIDC & IRSA (Працює і для AWS, і для LocalStack БЕЗ data-source)
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  # Це стандартний глобальний відбиток Root CA для AWS EKS.
  # Використовуємо його жорстко захардкодженим, щоб уникнути помилок завантаження!
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
