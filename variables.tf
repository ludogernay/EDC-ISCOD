# Région AWS dans laquelle seront créées les ressources
variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

# Préfixe utilisé pour nommer les ressources du projet
variable "project_name" {
  description = "Nom du projet utilisé comme préfixe de nommage"
  type        = string
  default     = "meditrack"
}

# Plage d'adresses IP du VPC
variable "vpc_cidr" {
  description = "CIDR principal du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Plage d'adresses IP du sous-réseau public
variable "public_subnet_cidr" {
  description = "CIDR du sous-réseau public"
  type        = string
  default     = "10.0.1.0/24"
}

# Zone de disponibilité AWS pour placer le sous-réseau et l'instance EC2
variable "availability_zone" {
  description = "Zone de disponibilité AWS"
  type        = string
  default     = "eu-west-3"
}

# Type d'instance EC2 demandé dans la consigne
variable "instance_type" {
  description = "Type de l'instance EC2"
  type        = string
  default     = "t3.micro"
}

# AMI Linux utilisée pour lancer une instance légère
# Cette valeur peut être adaptée selon la région et l'OS souhaité
variable "ami_id" {
  description = "Identifiant AMI pour l'instance EC2"
  type        = string
  default     = "ami-0c1c30571d2dae5c9"
}

# Nom unique du bucket S3
# Il doit être unique globalement sur AWS
variable "bucket_name" {
  description = "Nom unique du bucket S3"
  type        = string
}