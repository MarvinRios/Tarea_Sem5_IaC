output "dashboard_name" {
  description = "Nombre del CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
