variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "sqs_dlq_name" {
  description = "Nombre de la Dead Letter Queue"
  type        = string
}

variable "sqs_queue_name" {
  description = "Nombre de la cola principal"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email para alarmas (no usado directamente aquí)"
  type        = string
  default     = ""
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
