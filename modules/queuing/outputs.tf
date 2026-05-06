output "queue_arn" {
  description = "ARN de la cola SQS principal"
  value       = aws_sqs_queue.main.arn
}

output "queue_url" {
  description = "URL de la cola SQS principal"
  value       = aws_sqs_queue.main.url
}

output "dlq_arn" {
  description = "ARN de la Dead Letter Queue"
  value       = aws_sqs_queue.dlq.arn
}

output "dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_name" {
  description = "Nombre de la Dead Letter Queue (para métricas CloudWatch)"
  value       = aws_sqs_queue.dlq.name
}

output "queue_name" {
  description = "Nombre de la cola SQS principal"
  value       = aws_sqs_queue.main.name
}

output "sns_topic_arn" {
  description = "ARN del SNS topic de alarmas"
  value       = aws_sns_topic.dlq_alarm.arn
}
