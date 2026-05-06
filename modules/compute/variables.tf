variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas para las Lambdas (AZ-a y AZ-b)"
  type        = list(string)
}

variable "upload_lambda_sg_id" {
  description = "Security Group para la Lambda de subida"
  type        = string
}

variable "crop_lambda_sg_id" {
  description = "Security Group para la Lambda de recorte"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN de la cola SQS principal"
  type        = string
}

variable "upload_lambda_role_arn" {
  description = "ARN del rol IAM para la Lambda de subida"
  type        = string
}

variable "crop_lambda_role_arn" {
  description = "ARN del rol IAM para la Lambda de recorte"
  type        = string
}

variable "log_retention_days" {
  description = "Retención de logs en CloudWatch (días)"
  type        = number
  default     = 14
}

variable "upload_lambda_memory" {
  description = "Memoria para la Lambda de subida (MB)"
  type        = number
  default     = 256
}

variable "crop_lambda_memory" {
  description = "Memoria para la Lambda de recorte (MB)"
  type        = number
  default     = 256
}

variable "upload_lambda_timeout" {
  description = "Timeout para la Lambda de subida (segundos)"
  type        = number
  default     = 30
}

variable "crop_lambda_timeout" {
  description = "Timeout para la Lambda de recorte (segundos)"
  type        = number
  default     = 60
}
