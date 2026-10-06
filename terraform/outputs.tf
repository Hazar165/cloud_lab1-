output "alb_dns_name" {
  description = "Публічне DNS-ім'я Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "github_role_arn" {
  description = "ARN IAM-ролі для GitHub Actions. Збережіть його як секрет AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
