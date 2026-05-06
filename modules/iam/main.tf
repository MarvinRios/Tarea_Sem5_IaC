# ──────────────────────────────────────────────────────────
# Política de confianza común para Lambda
# ──────────────────────────────────────────────────────────
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ══════════════════════════════════════════════════════════
# ROL: upload-lambda-role
# ══════════════════════════════════════════════════════════
resource "aws_iam_role" "upload_lambda" {
  name               = "${var.name_prefix}-upload-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = { Name = "${var.name_prefix}-upload-lambda-role" }
}

# Managed policies: logs + VPC
resource "aws_iam_role_policy_attachment" "upload_basic_execution" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "upload_vpc_access" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Política custom: solo s3:PutObject en el prefijo uploads/
resource "aws_iam_policy" "upload_s3" {
  name        = "${var.name_prefix}-upload-lambda-s3-policy"
  description = "Permite a la Lambda de subida escribir solo en uploads/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowPutObjectUploads"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.s3_bucket_arn}/uploads/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "upload_s3_attach" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = aws_iam_policy.upload_s3.arn
}

# ══════════════════════════════════════════════════════════
# ROL: crop-lambda-role
# ══════════════════════════════════════════════════════════
resource "aws_iam_role" "crop_lambda" {
  name               = "${var.name_prefix}-crop-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = { Name = "${var.name_prefix}-crop-lambda-role" }
}

resource "aws_iam_role_policy_attachment" "crop_basic_execution" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc_access" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Política custom: S3 (leer uploads/ + escribir processed/)
resource "aws_iam_policy" "crop_s3" {
  name        = "${var.name_prefix}-crop-lambda-s3-policy"
  description = "Permite a la Lambda de recorte leer uploads/ y escribir en processed/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowGetObjectUploads"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${var.s3_bucket_arn}/uploads/*"
      },
      {
        Sid      = "AllowPutObjectProcessed"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.s3_bucket_arn}/processed/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crop_s3_attach" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = aws_iam_policy.crop_s3.arn
}

# Política custom: SQS — necesaria para que Lambda ESM pueda hacer polling
# El servicio de Lambda usa este rol para: ReceiveMessage, DeleteMessage,
# GetQueueAttributes y ChangeMessageVisibility.
resource "aws_iam_policy" "crop_sqs" {
  name        = "${var.name_prefix}-crop-lambda-sqs-policy"
  description = "Permite a la Lambda de recorte (via ESM) operar con la cola SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSOperations"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crop_sqs_attach" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = aws_iam_policy.crop_sqs.arn
}
