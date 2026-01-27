output "repository_urls" {
  description = "ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}

output "repository_arns" {
  description = "ECR repository ARNs"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.arn }
}

output "repository_names" {
  description = "ECR repository names"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.name }
}
