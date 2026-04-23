output "ecr_repository_url" {
  description = "URL của ECR repository trên LocalStack"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "Tên ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Tên ECS service"
  value       = aws_ecs_service.app.name
}

output "deployed_image" {
  description = "Image đang được deploy"
  value       = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group cho app"
  value       = aws_cloudwatch_log_group.app.name
}