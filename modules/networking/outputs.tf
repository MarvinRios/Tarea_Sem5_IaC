output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas (para las Lambdas)"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "upload_lambda_sg_id" {
  description = "ID del Security Group de la Lambda de subida"
  value       = aws_security_group.upload_lambda.id
}

output "crop_lambda_sg_id" {
  description = "ID del Security Group de la Lambda de recorte"
  value       = aws_security_group.crop_lambda.id
}

output "s3_vpce_id" {
  description = "ID del VPC Endpoint de S3"
  value       = aws_vpc_endpoint.s3.id
}
