locals {
  name_prefix = "image-processor-${var.environment}"
}

data "aws_caller_identity" "current" {}

# ─────────────────────────────────────────────
# MÓDULO: Networking
# VPC, subnets, IGW, route tables, SGs, VPC Endpoint S3
# ─────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  environment = var.environment
  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  aws_region  = var.aws_region
}

# ─────────────────────────────────────────────
# MÓDULO: Storage (S3)
# Bucket con cifrado AES-256, versionado, lifecycle rules
# ─────────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  environment   = var.environment
  name_prefix   = local.name_prefix
  bucket_suffix = var.bucket_suffix
}

# ─────────────────────────────────────────────
# MÓDULO: Queuing (SQS)
# Cola principal + Dead Letter Queue
# ─────────────────────────────────────────────
module "queuing" {
  source = "./modules/queuing"

  environment        = var.environment
  name_prefix        = local.name_prefix
  visibility_timeout = var.sqs_visibility_timeout
  alert_email        = var.alert_email
}

# ─────────────────────────────────────────────
# RECURSO PUENTE: Política de SQS para permitir que S3 envíe notificaciones
# Se define aquí (y no en el módulo queuing) para evitar dependencias circulares.
# ─────────────────────────────────────────────
resource "aws_sqs_queue_policy" "allow_s3_notifications" {
  queue_url = module.queuing.queue_url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3ToSendMessages"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = module.queuing.queue_arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = module.storage.bucket_arn
          }
        }
      }
    ]
  })
}

# ─────────────────────────────────────────────
# RECURSO PUENTE: Notificación S3 → SQS cuando se crea objeto en uploads/
# Se define aquí porque depende de AMBOS módulos (storage y queuing).
# ─────────────────────────────────────────────
resource "aws_s3_bucket_notification" "uploads_to_sqs" {
  bucket = module.storage.bucket_name

  queue {
    queue_arn     = module.queuing.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_notifications]
}

# ─────────────────────────────────────────────
# MÓDULO: IAM
# Roles y políticas de mínimo privilegio para las Lambdas
# ─────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  environment    = var.environment
  name_prefix    = local.name_prefix
  s3_bucket_arn  = module.storage.bucket_arn
  sqs_queue_arn  = module.queuing.queue_arn
  sqs_dlq_arn    = module.queuing.dlq_arn
  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
}

# ─────────────────────────────────────────────
# MÓDULO: Compute (Lambda)
# Funciones Lambda: upload y crop + ESM trigger SQS
# ─────────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  environment              = var.environment
  name_prefix              = local.name_prefix
  vpc_id                   = module.networking.vpc_id
  private_subnet_ids       = module.networking.private_subnet_ids
  upload_lambda_sg_id      = module.networking.upload_lambda_sg_id
  crop_lambda_sg_id        = module.networking.crop_lambda_sg_id
  s3_bucket_name           = module.storage.bucket_name
  sqs_queue_arn            = module.queuing.queue_arn
  upload_lambda_role_arn   = module.iam.upload_lambda_role_arn
  crop_lambda_role_arn     = module.iam.crop_lambda_role_arn
  log_retention_days       = var.log_retention_days
  upload_lambda_memory     = var.upload_lambda_memory
  crop_lambda_memory       = var.crop_lambda_memory
  upload_lambda_timeout    = var.upload_lambda_timeout
  crop_lambda_timeout      = var.crop_lambda_timeout
}

# ─────────────────────────────────────────────
# MÓDULO: API Gateway
# HTTP API v2 con ruta POST /upload → Lambda
# ─────────────────────────────────────────────
module "api" {
  source = "./modules/api"

  environment              = var.environment
  name_prefix              = local.name_prefix
  upload_lambda_invoke_arn = module.compute.upload_lambda_invoke_arn
  upload_lambda_name       = module.compute.upload_lambda_name
  log_retention_days       = var.log_retention_days
  aws_region               = var.aws_region
}

# ─────────────────────────────────────────────
# MÓDULO: Observability
# Alarma CloudWatch DLQ + SNS topic
# ─────────────────────────────────────────────
module "observability" {
  source = "./modules/observability"

  environment    = var.environment
  name_prefix    = local.name_prefix
  sqs_dlq_name   = module.queuing.dlq_name
  sqs_queue_name = module.queuing.queue_name
  alert_email    = var.alert_email
  aws_region     = var.aws_region
}
