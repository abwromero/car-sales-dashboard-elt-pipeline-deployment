variable "ecs_app_name" {
    description = "Name of the service using ECS"
    type = string
}

variable "docker_image" {
    description = "Docker Image to use"
    type = string
}

variable "ecs_container_cpu_size" {
    description = "CPU size for the ECS task (One vCPU is 1024 units)"
    type = number
}

variable "ecs_container_memory_size" {
    description = "Memory size for the ECS task in MB"
    type = number
}

variable "ecs_task_cpu_size" {
    description = "CPU size for the ECS task (One vCPU is 1024 units)"
    type = string
}

variable "ecs_task_memory_size" {
    description = "Memory size for the ECS task in MB"
    type = string
}

variable "vpc_id" {
    description = "VPC used by the ECS application"
    type = string
}

variable "vpc_cidr_block" {
    description = "CIDR block assigned for the VPC"
    type = string
}

variable "vpc_endpoint_service_name" {
  description = "Service name of the VPC Endpoint for S3. Format: con.amazonaws.<region>.<service>"
  type = string
  default = "com.amazonaws.us-east-1.s3"
}

variable "public_subnet_ids" {
    description = "IDs of the public subnets used by ECS"
}

variable "health_check_path" {
    description = "Path where the load balancer will check the health status of the application"
}

variable "private_subnet_ids" {
    description = "IDs of the private subnets used by ECS"
}

variable "alb_listener_port" {
    description = "Listener port for the ALB"
    type = string
}

variable "alb_listener_protocol" {
    description = "Listener protocol for the ALB"
    type = string
}

variable "container_environment" {
    description = "Environment variables required for the image to run"
}

variable "container_port" {
    description = "Assigned port inside the container image"
    type = number
}

variable "host_port" {
    description = "Port given to the service outside of the container"
    type = number
}

variable "ecs_efs_vol_id" {
    description = "ID of the EFS volume to be attached to the ECS cluster"
    type = string
}

variable "mount_point_container_path" {
    description = "Path inside the container for the EFS volume"
    type = string
}

variable "alb_target_group_port" {
    description = "Port for the ALB target group used by the ECS application"
}

variable "ecs_efs_access_point_id" {
    description = "EFS Access Point ID for ECS to access the file system"
}