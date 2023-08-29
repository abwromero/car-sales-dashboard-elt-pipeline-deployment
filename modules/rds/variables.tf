variable "vpc_id" {
  description = "Generated ID for the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC the RDS instance is assigned to"
  type = string
}

variable "rds_subnets_ids" {
  description = "Subnet IDs to assign for the RDS instance"
  type        = list(string)
}

variable "microservice_name" {
  description = "Name of the microservice the RDS instance is assigned to"
  type        = string
  default     = "rds_default"
}

variable "rds_ingress_security_groups" {
  description = "Applications that can access the RDS instance through security group reference"
  type = list(string)
}

variable "rds_allocated_storage" {
  description = "Allocated storage for the RDS instance in GBs"
  type        = number
  default     = 100
}

variable "rds_engine" {
  description = "Engine type for the RDS instance"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Version used for the engine of the RDS instance"
  type        = number
  default     = 15
}

variable "rds_instance_class" {
  description = "Size of the instance used for the RDS instance"
  type        = string
  default     = "db.m5.large"
}

variable "rds_iops" {
  description = "Provisioned IOPS for the RDS instance"
  type        = number
  default     = 1000
}

variable "rds_max_allocated_storage" {
  description = "Maximum allowable storage for the use of the RDS instance in GBs"
  type        = number
  default     = 150
}

variable "rds_public_access" {
  description = "Allow RDS for public access"
  type        = bool
  default     = false
}

variable "rds_storage_type" {
  description = "Storage type for the RDS instance"
  type        = string
  default     = "io1"
}