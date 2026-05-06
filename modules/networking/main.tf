data "aws_availability_zones" "available" {
  state = "available"
}

# ──────────────────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name_prefix}-vpc" }
}

# ──────────────────────────────────────────────────────────
# Internet Gateway
# ──────────────────────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

# ──────────────────────────────────────────────────────────
# Subnets Públicas (AZ-a y AZ-b)
# ──────────────────────────────────────────────────────────
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-public-a"
    Tier = "public"
    AZ   = "a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-public-b"
    Tier = "public"
    AZ   = "b"
  }
}

# ──────────────────────────────────────────────────────────
# Subnets Privadas (AZ-a y AZ-b)
# ──────────────────────────────────────────────────────────
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.name_prefix}-private-a"
    Tier = "private"
    AZ   = "a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.name_prefix}-private-b"
    Tier = "private"
    AZ   = "b"
  }
}

# ──────────────────────────────────────────────────────────
# Route Table Pública → IGW
# ──────────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ──────────────────────────────────────────────────────────
# Route Tables Privadas (SIN NAT)
# El VPC Gateway Endpoint de S3 inyecta sus rutas automáticamente.
# ──────────────────────────────────────────────────────────
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-rt-private-a" }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-rt-private-b" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

# ──────────────────────────────────────────────────────────
# VPC Endpoint: S3 Gateway
# Inyecta rutas en las route tables privadas para que el tráfico
# a S3 nunca salga a internet ni pase por NAT.
# ──────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_a.id,
    aws_route_table.private_b.id,
  ]

  # Política: permite acciones necesarias de las Lambdas sobre cualquier bucket.
  # Nota: Se usa "*" para no generar dependencia circular con el módulo de storage.
  # En producción real, se puede restringir al ARN específico del bucket.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource  = "*"
    }]
  })

  tags = { Name = "${var.name_prefix}-vpce-s3" }
}

# ──────────────────────────────────────────────────────────
# Security Group: Upload Lambda
# Inbound: ninguno (API GW invoca Lambda vía servicio AWS, no por red)
# Outbound: solo HTTPS al S3 Gateway Endpoint
# ──────────────────────────────────────────────────────────
resource "aws_security_group" "upload_lambda" {
  name        = "${var.name_prefix}-sg-upload-lambda"
  description = "Upload Lambda: sin inbound; outbound HTTPS solo a S3 via endpoint"
  vpc_id      = aws_vpc.main.id

  egress {
    description     = "HTTPS a S3 via Gateway Endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  tags = { Name = "${var.name_prefix}-sg-upload-lambda" }
}

# ──────────────────────────────────────────────────────────
# Security Group: Crop Lambda
# Inbound: ninguno (invocada por Lambda ESM desde el servicio)
# Outbound: solo HTTPS al S3 Gateway Endpoint
# ──────────────────────────────────────────────────────────
resource "aws_security_group" "crop_lambda" {
  name        = "${var.name_prefix}-sg-crop-lambda"
  description = "Crop Lambda: sin inbound; outbound HTTPS solo a S3 via endpoint"
  vpc_id      = aws_vpc.main.id

  egress {
    description     = "HTTPS a S3 via Gateway Endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  tags = { Name = "${var.name_prefix}-sg-crop-lambda" }
}
