# ==========================================
# ІНІЦІАЛІЗАЦІЯ ПРОВАЙДЕРІВ
# ==========================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
  }
}

module "vpc" {
  source             = "./modules/vpc"
  environment        = var.environment
  project_name       = var.project_name
  vpc_cidr_block     = var.vpc_cidr
  public_subnets     = var.public_subnets_cidr
  private_subnets    = var.private_subnets_cidr
  availability_zones = var.availability_zones
  vpc_name           = "${var.project_name}-${var.environment}-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = var.ecr_repo_name
  scan_on_push = var.scan_on_push
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# Повернув ReadOnly за рекомендацією ментора (Principle of Least Privilege)
resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

module "eks" {
  source = "./modules/eks"
  count  = var.enable_eks ? 1 : 0

  environment               = var.environment
  cluster_name              = var.cluster_name
  cluster_version           = var.cluster_version
  subnet_ids                = module.vpc.private_subnet_ids

  cluster_role_arn          = aws_iam_role.eks_cluster_role.arn
  node_role_arn             = aws_iam_role.eks_node_role.arn

  node_instance_types       = var.node_instance_types
  node_min_size             = var.node_min_size
  node_max_size             = var.node_max_size
  node_desired_size         = var.node_desired_size
  enabled_cluster_log_types = var.enabled_cluster_log_types

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]
}

module "jenkins" {
  source     = "./modules/jenkins"
  namespace  = "jenkins"
  depends_on = [module.eks]
}

module "argo_cd" {
  source      = "./modules/argo_cd"
  namespace   = "argocd"
  github_repo = var.github_repo
  depends_on  = [module.eks]
}

# ---------------------------------------------
# НАЛАШТУВАННЯ HELM ПРОВАЙДЕРА
# ---------------------------------------------
data "aws_eks_cluster" "main" {
  name       = module.eks[0].cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "main" {
  name       = module.eks[0].cluster_name
  depends_on = [module.eks]
}

provider "helm" {
  kubernetes = {
    host                   = replace(data.aws_eks_cluster.main.endpoint, "localhost.localstack.cloud", "172.18.0.2")

    # ВИПРАВЛЕНО: Якщо це dev (insecure=true), передаємо null (нічого). Якщо prod - даємо сертифікат.
    cluster_ca_certificate = var.environment == "dev" ? null : base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)

    token                  = data.aws_eks_cluster_auth.main.token
    insecure               = var.environment == "dev" ? true : false
  }
}
