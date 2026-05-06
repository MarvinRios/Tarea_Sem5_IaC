variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "upload_lambda_invoke_arn" {
  description = "ARN de invocación de la Lambda de subida"
  type        = string
}

variable "upload_lambda_name" {
  description = "Nombre de la Lambda de subida (para el permiso de invocación)"
  type        = string
}

variable "log_retention_days" {
  description = "Retención de logs de API Gateway en días"
  type        = number
  default     = 14
}

variable "aws_region" {
  type = string
}
