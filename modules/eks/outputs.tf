output "cluster_name" {
  description = "Назва створеного EKS кластера"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Ендпоінт кластера"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "CA Сертифікат кластера для Helm"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}
