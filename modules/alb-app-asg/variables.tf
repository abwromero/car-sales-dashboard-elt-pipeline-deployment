variable "vpc_id" {
    description = "VPC ID for the Application Load Balancer and Auto-Scaling Group"
    type = string
}

variable "target_app_name" {
    description = "Name of the target application for the ALB-ASG"
    type = string
}

variable "alb_listener_port" {
    description = "Listener port for the ALB"
    type = string
}

variable "alb_listener_protocol" {
    description = "Listener protocol for the ALB"
    type = string
}

variable "asg_scaling_target" {
    description = "EC2 or ECS target to scale"
    type = string
}

variable "asg_scalable_dimension" {
    description = "API of the application to scale"
    type = string
}

variable "asg_service_namespace" {
    description = "Service namespace assigned for the ASG"
    type = string
}

variable "asg_metrics_identifier" {
    description = "String assignment for the ASG policy name"
    type = list(string)
}

variable "asg_api_metrics_monitoring" {
    description = "Metrics to monitor for the ASG"
    type = list(string)
}

variable "asg_api_metrics_monitoring_threshold" {
    description = "Target values the ASG should refer to when scaling up"
    type = list(number)
}

variable "public_subnet_ids" {
    description = "Public Subnet IDs for the ALB and ASG"
}

variable "health_check_path" {
    description = "Path where the load balancer will check the health status of the application"
}

variable "private_subnet_ids" {
    description = "Private Subnet IDs for the ALB and ASG"
}

variable "alb_target_group_port" {
    description = "Port for the ALB target group"
}