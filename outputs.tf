# ID du VPC créé
output "vpc_id" {
  description = "Identifiant du VPC"
  value       = aws_vpc.main.id
}

# ID du sous-réseau public
output "public_subnet_id" {
  description = "Identifiant du sous-réseau public"
  value       = aws_subnet.public_subnet.id
}

# IP publique de l'instance EC2
output "ec2_public_ip" {
  description = "Adresse IP publique de l'instance EC2"
  value       = aws_instance.web.public_ip
}

# URL du site statique S3
output "s3_website_url" {
  description = "URL du site statique hébergé sur S3"
  value       = aws_s3_bucket_website_configuration.static_site_config.website_endpoint
}

# Nom de domaine de la distribution CloudFront
output "cloudfront_domain_name" {
  description = "Nom de domaine CloudFront"
  value       = aws_cloudfront_distribution.cdn.domain_name
}