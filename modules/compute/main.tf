data "archive_file" "upload_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda_src/upload"
  output_path = "${path.root}/lambda_builds/upload.zip"
}

data "archive_file" "crop_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda_src/crop"
  output_path = "${path.root}/lambda_builds/crop.zip"
}

# ──────────────────────────────────────────────────────────
# Log Groups
# ──────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "upload_lambda" {
  name              = "/aws/lambda/${var.name_prefix}-upload"
  retention_in_days = var.log_retention_days

  tags = { Name = "${var.name_prefix}-upload-logs" }
}

resource "aws_cloudwatch_log_group" "crop_lambda" {
  name              = "/aws/lambda/${var.name_prefix}-crop"
  retention_in_days = var.log_retention_days

  tags = { Name = "${var.name_prefix}-crop-logs" }
}

# ──────────────────────────────────────────────────────────
# Lambda: upload-lambda
# Responsabilidad: recibir imagen de API Gateway y guardarla en S3 uploads/
# ──────────────────────────────────────────────────────────
resource "aws_lambda_function" "upload" {
  function_name = "${var.name_prefix}-upload"
  description   = "Recibe imágenes vía API Gateway y las almacena en S3 uploads/"
  filename      = data.archive_file.upload_lambda.output_path
  source_code_hash = data.archive_file.upload_lambda.output_base64sha256

  runtime = "nodejs20.x"
  handler = "index.handler"
  role    = var.upload_lambda_role_arn
  memory_size = var.upload_lambda_memory
  timeout     = var.upload_lambda_timeout

  environment {
    variables = {
      S3_BUCKET     = var.s3_bucket_name
      UPLOAD_PREFIX = "uploads/"
      ENVIRONMENT   = var.environment
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.upload_lambda_sg_id]
  }

  # Lambda crea el log group automáticamente, pero usamos el que ya creamos
  depends_on = [aws_cloudwatch_log_group.upload_lambda]

  tags = { Name = "${var.name_prefix}-upload" }
}

# ──────────────────────────────────────────────────────────
# Lambda: crop-lambda
# Responsabilidad: leer imagen de S3 uploads/, recortarla a 40x40 circular,
#                  guardar PNG en S3 processed/
# ──────────────────────────────────────────────────────────
resource "aws_lambda_function" "crop" {
  function_name = "${var.name_prefix}-crop"
  description   = "Recorta imágenes a 40x40px circular PNG y las guarda en S3 processed/"
  filename      = data.archive_file.crop_lambda.output_path
  source_code_hash = data.archive_file.crop_lambda.output_base64sha256

  runtime = "nodejs20.x"
  handler = "index.handler"
  role    = var.crop_lambda_role_arn
  memory_size = var.crop_lambda_memory
  timeout     = var.crop_lambda_timeout

  environment {
    variables = {
      S3_BUCKET        = var.s3_bucket_name
      UPLOAD_PREFIX    = "uploads/"
      PROCESSED_PREFIX = "processed/"
      ENVIRONMENT      = var.environment
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.crop_lambda_sg_id]
  }

  depends_on = [aws_cloudwatch_log_group.crop_lambda]

  tags = { Name = "${var.name_prefix}-crop" }
}

# ──────────────────────────────────────────────────────────
# Event Source Mapping: SQS → crop-lambda
#   - Batch size: 5 mensajes por invocación
#   - ReportBatchItemFailures: solo reintenta los mensajes fallidos,
#     no todo el batch
# ──────────────────────────────────────────────────────────
resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.crop.arn

  batch_size                         = 5
  maximum_batching_window_in_seconds = 0
  enabled                            = true

  function_response_types = ["ReportBatchItemFailures"]
}
