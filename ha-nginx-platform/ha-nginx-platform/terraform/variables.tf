variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for naming every resource"
  type        = string
  default     = "ha-nginx"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "One public subnet per Availability Zone (an ALB needs at least 2 AZs)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_count" {
  description = "Number of Nginx EC2 servers"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to your SSH PUBLIC key (uploaded to AWS as a key pair)"
  type        = string
  default     = "~/.ssh/ha-nginx-key.pub"
}

variable "private_key_path" {
  description = "Path to the matching PRIVATE key (written into the Ansible inventory)"
  type        = string
  default     = "~/.ssh/ha-nginx-key"
}

variable "ssh_allowed_cidr" {
  description = "Who may SSH to the servers, e.g. 203.0.113.10/32 (your public IP)"
  type        = string
}

variable "alert_email" {
  description = "Email that receives CloudWatch alarms (leave empty to skip)"
  type        = string
  default     = ""
}

variable "site_slugs" {
  description = "URL paths of the 5 websites (used only for the outputs)"
  type        = list(string)
  default     = ["employee", "customer", "insurance", "reports", "support"]
}
