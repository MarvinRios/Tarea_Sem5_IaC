##############################################################################
# modules/api/main.tf
#
# API Gateway HTTP API v2:
#   - Ruta: POST /upload
#   - Protocolo: HTTPS (TLS 1.2+ gestionado por AWS para HTTP APIs)
#   - Payload format: 2.0
#   - CORS: habilitado
#   - Stage: $default con auto-deploy
#   - Throttling: reducido a 100 rps para el lab (el diagrama dice 10,000 rps,
#     pero eso no aplica para un lab y AWS puede limitar en cuentas nuevas)
#   - Access logs a CloudWatch
#
# JUSTIFICACIÓN DE CAMBIO DE THROTTLING:
#   El diagrama especifica 10,000 rps. Para este laboratorio se configura
#   100 rps ya que es más que suficiente para pruebas y evita costos
#   inesperados por invocaciones accidentales masivas.
##############################################################################

# ──────────────────────────────────────────────────────────
# HTTP API v2
# ──────────────────────────────────────────────────────────
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.name_prefix}-api"
  description   = "API HTTP v2 para subir imágenes — ${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers  = ["Content-Type", "Authorization", "X-Requested-With"]
    allow_methods  = ["POST", "OPTIONS"]
    allow_origins  = ["*"]
    expose_headers = []
    max_age        = 300
  }

  tags = { Name = "${var.name_prefix}-api" }
}

# ──────────────────────────────────────────────────────────
# Log Group para access logs de API Gateway
# ──────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = { Name = "${var.name_prefix}-apigw-logs" }
}

# ──────────────────────────────────────────────────────────
# Stage: $default con auto-deploy y access logs en JSON
# ──────────────────────────────────────────────────────────
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw.arn

    # Formato JSON de access log (según especificación del diagrama)
    format = jsonencode({
      requestId        = "$context.requestId"
      sourceIp         = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      protocol         = "$context.protocol"
      httpMethod       = "$context.httpMethod"
      resourcePath     = "$context.resourcePath"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100 # Reducido de 10,000 a 100 rps para el lab
  }

  tags = { Name = "${var.name_prefix}-stage-default" }
}

# ──────────────────────────────────────────────────────────
# Integración: API Gateway → upload-lambda (Lambda Proxy)
# ──────────────────────────────────────────────────────────
resource "aws_apigatewayv2_integration" "upload_lambda" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.upload_lambda_invoke_arn
  payload_format_version = "2.0"  # Payload format version 2.0 (según diagrama)

  timeout_milliseconds = 29000  # 29s (límite máximo de HTTP API)
}

# ──────────────────────────────────────────────────────────
# Ruta: POST /upload
# ──────────────────────────────────────────────────────────
resource "aws_apigatewayv2_route" "post_upload" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_lambda.id}"
}

# ──────────────────────────────────────────────────────────
# Permiso: API Gateway puede invocar la Lambda de subida
# ──────────────────────────────────────────────────────────
resource "aws_lambda_permission" "apigw_invoke_upload" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*/upload"
}
