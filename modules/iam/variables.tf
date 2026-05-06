variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3 de imágenes"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN de la cola SQS principal"
  type        = string
}

variable "sqs_dlq_arn" {
  description = "ARN de la Dead Letter Queue"
  type        = string
}

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}
