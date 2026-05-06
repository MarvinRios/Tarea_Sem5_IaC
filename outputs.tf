output "api_endpoint" {
  description = "URL del endpoint POST /upload"
  value       = module.api.api_endpoint
}

output "bucket_name" {
  description = "Nombre del bucket S3"
  value       = module.storage.bucket_name
}

output "sqs_queue_url" {
  description = "URL de la cola SQS principal"
  value       = module.queuing.queue_url
}

output "sqs_dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = module.queuing.dlq_url
}

output "upload_lambda_name" {
  description = "Nombre de la Lambda de subida"
  value       = module.compute.upload_lambda_name
}

output "crop_lambda_name" {
  description = "Nombre de la Lambda de recorte"
  value       = module.compute.crop_lambda_name
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = module.networking.vpc_id
}
