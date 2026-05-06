variable "environment" {
  description = "Entorno de despliegue (dev, qa, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "El entorno debe ser dev, qa o prod."
  }
}

variable "aws_region" {
  description = "Región de AWS donde se despliegan los recursos"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "bucket_suffix" {
  description = "Sufijo único para el nombre del bucket S3 (debe ser único globalmente)"
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
  description = "Memoria para la Lambda de recorte (MB). Se puede reducir en dev/qa para ahorrar costos."
  type        = number
  default     = 256
}

variable "crop_lambda_timeout" {
  description = "Timeout para la Lambda de recorte (segundos)"
  type        = number
  default     = 60
}

variable "upload_lambda_timeout" {
  description = "Timeout para la Lambda de subida (segundos)"
  type        = number
  default     = 30
}

variable "sqs_visibility_timeout" {
  description = "Visibility timeout de SQS en segundos (debe ser >= 6x el timeout de crop Lambda)"
  type        = number
  default     = 360
}

variable "alert_email" {
  description = "Email para recibir alarmas de CloudWatch via SNS. Vacío = sin notificaciones."
  type        = string
  default     = ""
}
