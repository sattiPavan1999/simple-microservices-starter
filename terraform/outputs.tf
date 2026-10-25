output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Use for the ALB"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Use for ECS tasks / EC2 / EKS nodes"
  value       = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "frontend_security_group_id" {
  value = aws_security_group.frontend.id
}

output "backend_security_group_ids" {
  value = { for k, sg in aws_security_group.backend : k => sg.id }
}

output "rds_endpoints" {
  description = "Hostname of each database"
  value       = { for k, db in aws_db_instance.main : k => db.address }
}

output "database_url_ssm_parameters" {
  description = "SSM parameter names holding each service's DATABASE_URL"
  value       = { for k, p in aws_ssm_parameter.database_url : k => p.name }
}

# ---------- EKS ----------
output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "eks_kubeconfig_command" {
  description = "Run this to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
