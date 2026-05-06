variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "visibility_timeout" {
  description = "Visibility timeout de la cola en segundos (debe ser >= 6x timeout de Lambda)"
  type        = number
  default     = 360
}

variable "alert_email" {
  description = "Email para notificaciones SNS (vacío = sin suscripción)"
  type        = string
  default     = ""
}
