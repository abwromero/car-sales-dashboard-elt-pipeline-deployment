variable "vpc_name" {
  description = "Name for the VPC generated"
  type        = string
  default     = "main"
}

variable "vpc_cidr_block" {
  description = "CIDR Block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnets_cidr_blocks" {
  description = "CIDR blocks for the public subnets inside the VPC"
  type        = list(string)
  default     = ["192.168.0.0/20", "192.168.16.0/20"]
}

variable "private_subnets_cidr_blocks" {
  description = "CIDR blocks for the private subnets inside the VPC"
  type        = list(string)
  default     = ["192.168.32.0/20", "192.168.48.0/20"]
}

variable "azs" {
  description = "Availability Zones for the VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}