resource "aws_s3_bucket" "images" {
  bucket = "${var.name_prefix}-images-${var.bucket_suffix}"

  # Previene destrucción accidental en producción
  lifecycle {
    prevent_destroy = false # Cambiar a true en prod real
  }

  tags = { Name = "${var.name_prefix}-images-${var.bucket_suffix}" }
}

# ──────────────────────────────────────────────────────────
# Bloquear todo acceso público
# ──────────────────────────────────────────────────────────
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────────────────────
# Cifrado del lado del servidor: AES-256
# ──────────────────────────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ──────────────────────────────────────────────────────────
# Versionado habilitado
# ──────────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ──────────────────────────────────────────────────────────
# Lifecycle Rules
#   - uploads/   → objetos expiran a los 30 días
#   - processed/ → objetos expiran a los 90 días
# También limpia versiones no actuales para no acumular costos.
# ──────────────────────────────────────────────────────────
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  # Depende del versionado para que las reglas apliquen correctamente
  depends_on = [aws_s3_bucket_versioning.images]

  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  rule {
    id     = "expire-processed"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# ──────────────────────────────────────────────────────────
# Bucket Policy: denegar solicitudes sin TLS (enforce HTTPS)
# ──────────────────────────────────────────────────────────
resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.images.id

  # Esperar a que el block public access esté activo antes de aplicar política
  depends_on = [aws_s3_bucket_public_access_block.images]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.images.arn,
          "${aws_s3_bucket.images.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ──────────────────────────────────────────────────────────
# CORS (opcional — útil si el cliente sube directamente a S3 en el futuro)
# ──────────────────────────────────────────────────────────
resource "aws_s3_bucket_cors_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}
