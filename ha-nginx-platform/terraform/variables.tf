variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for naming all resources"
  type        = string
  default     = "ha-nginx"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the 2 public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "AZs to spread the subnets/EC2 instances across"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "instance_type" {
  description = "EC2 instance type for Nginx web servers and the monitoring server"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the existing EC2 key pair to attach (create with: aws ec2 create-key-pair)"
  type        = string
  default     = "ha-nginx-key"
}

variable "my_ip" {
  description = "Your IP in CIDR form, e.g. 49.36.XX.XX/32 (used to restrict SSH, Prometheus, Grafana access). Get it from https://checkip.amazonaws.com"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI id for ap-south-1. Update if using a different region."
  type        = string
  default     = "ami-03f4878755434977f"
}
