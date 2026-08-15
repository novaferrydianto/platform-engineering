output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA bundle for the API server"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group attached to the control plane ENIs"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group attached to worker nodes"
  value       = aws_security_group.nodes.id
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN — use it to build IRSA trust policies"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL without scheme, for IRSA condition keys"
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

output "kms_key_arn" {
  description = "KMS key encrypting cluster secrets and node volumes"
  value       = aws_kms_key.eks.arn
}
