output "upload_lambda_role_arn" {
  description = "ARN del rol de la Lambda de subida"
  value       = aws_iam_role.upload_lambda.arn
}

output "upload_lambda_role_name" {
  description = "Nombre del rol de la Lambda de subida"
  value       = aws_iam_role.upload_lambda.name
}

output "crop_lambda_role_arn" {
  description = "ARN del rol de la Lambda de recorte"
  value       = aws_iam_role.crop_lambda.arn
}

output "crop_lambda_role_name" {
  description = "Nombre del rol de la Lambda de recorte"
  value       = aws_iam_role.crop_lambda.name
}
