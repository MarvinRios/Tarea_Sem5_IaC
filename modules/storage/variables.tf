variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "bucket_suffix" {
  description = "Sufijo único para el nombre del bucket (debe ser único globalmente en S3)"
  type        = string
}
