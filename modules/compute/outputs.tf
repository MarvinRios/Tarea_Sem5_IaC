output "upload_lambda_name" {
  description = "Nombre de la Lambda de subida"
  value       = aws_lambda_function.upload.function_name
}

output "upload_lambda_arn" {
  description = "ARN de la Lambda de subida"
  value       = aws_lambda_function.upload.arn
}

output "upload_lambda_invoke_arn" {
  description = "ARN de invocación de la Lambda de subida (para API Gateway)"
  value       = aws_lambda_function.upload.invoke_arn
}

output "crop_lambda_name" {
  description = "Nombre de la Lambda de recorte"
  value       = aws_lambda_function.crop.function_name
}

output "crop_lambda_arn" {
  description = "ARN de la Lambda de recorte"
  value       = aws_lambda_function.crop.arn
}
