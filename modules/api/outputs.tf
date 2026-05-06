output "api_endpoint" {
  description = "URL base del API Gateway (ejemplo: https://xxx.execute-api.us-east-1.amazonaws.com)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_id" {
  description = "ID del HTTP API"
  value       = aws_apigatewayv2_api.main.id
}

output "upload_url" {
  description = "URL completa del endpoint POST /upload"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/upload"
}
