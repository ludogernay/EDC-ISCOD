##############################################
# Provider AWS
##############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

##############################################
# VPC et sous-réseau public
##############################################

# Création du VPC principal
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "meditrack-vpc"
  }
}

# Création d'un sous-réseau public dans le VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "meditrack-public-subnet"
  }
}

# Passerelle Internet pour permettre la sortie vers Internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "meditrack-igw"
  }
}

# Table de routage pour envoyer le trafic Internet vers la passerelle
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "meditrack-public-rt"
  }
}

# Association du sous-réseau public à la table de routage
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

##############################################
# Security Group pour EC2
##############################################

# Groupe de sécurité minimal pour l'instance EC2
# Ici, seul SSH est ouvert pour l'administration
resource "aws_security_group" "ec2_sg" {
  name        = "meditrack-ec2-sg"
  description = "Security group de l instance EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "meditrack-ec2-sg"
  }
}

##############################################
# Instance EC2 légère
##############################################

# Création d'une instance EC2 t3.micro
# Aucune installation applicative n'est faite ici
resource "aws_instance" "web" {
  ami                         = "ami-0be40a46b4111e7f5"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "meditrack-ec2"
  }
}

##############################################
# Bucket S3 pour hébergement statique
##############################################

# Création du bucket S3
resource "aws_s3_bucket" "static_site" {
  bucket = "meditrack-static-site-2026-demo"

  tags = {
    Name = "meditrack-static-site"
  }
}

# Configuration du bucket pour héberger un site statique
resource "aws_s3_bucket_website_configuration" "static_site_config" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Upload du fichier principal HTML
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "index.html"
  source       = "index.html"
  etag         = filemd5("index.html")
  content_type = "text/html"
}

# Upload du fichier CSS
resource "aws_s3_object" "style_css" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "style.css"
  source       = "style.css"
  etag         = filemd5("style.css")
  content_type = "text/css"
}

# Upload du error
resource "aws_s3_object" "error_css" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "error.html"
  source       = "error.html"
  etag         = filemd5("error.html")
  content_type = "text/html"
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

##############################################
# Distribution CloudFront
##############################################

# Distribution CloudFront pour diffuser le contenu du site statique
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket_website_configuration.static_site_config.website_endpoint
    origin_id   = "s3-static-site-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-static-site-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "meditrack-cloudfront"
  }
}