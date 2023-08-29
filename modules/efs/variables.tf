variable "vpc_id" {
  description = "ID generated for the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block generated for the VPC"
  type        = string
}

variable "efs_subnet_ids" {
  description = "Subnet IDs assigned for the EFS"
  type        = list(string)
}

variable "efs_app_name" {
  description = "Name of the application running with the EFS"
  type = string
}

variable "service_security_group" {
  description = "Security group of the service the EFS was initialized for"
  type = string
}

variable "efs_access_point_root_path" {
  description = "Root path for the EFS access point"
  type = string
}