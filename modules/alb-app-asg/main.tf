# REFERENCE:
# - Create an AWS ECS Cluster Using Terraform by Tacio Nery
#   Link: https://dev.to/thnery/create-an-aws-ecs-cluster-using-terraform-g80

resource "aws_security_group" "alb_security_group" {
    vpc_id = var.vpc_id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "${var.target_app_name}-alb-sg"
    }
}

resource "aws_alb" "alb_service" {
    name = "${var.target_app_name}-alb"
    internal = false
    load_balancer_type = "application"
    subnets = var.public_subnet_ids
    security_groups = [aws_security_group.alb_security_group.id]

    tags = {
        Name = "${var.target_app_name}-alb"
    }
}

resource "aws_lb_target_group" "target_group" {
    name = "${var.target_app_name}-target-group"
    port = var.alb_target_group_port
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = var.vpc_id

    health_check {
        healthy_threshold = "3"
        interval = "10"
        protocol = "HTTP"
        matcher = "200"
        timeout = "3"
        path = var.health_check_path
        unhealthy_threshold = "3"
    }

    tags = {
        Name = "${var.target_app_name}-load-balancer-target-group"
    }
}

resource "aws_lb_listener" "target_alb_listener" {
    load_balancer_arn = aws_alb.alb_service.id
    port = var.alb_listener_port
    protocol = var.alb_listener_protocol
    
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.target_group.id
    }
}

resource "aws_appautoscaling_target" "target" {
    max_capacity = 2
    min_capacity = 1
    resource_id = "service/${var.asg_scaling_target}"
    scalable_dimension = var.asg_scalable_dimension
    service_namespace = var.asg_service_namespace
}

resource "aws_appautoscaling_policy" "app_scaling_policy" {
    count = length(var.asg_api_metrics_monitoring)
    name = "${var.target_app_name}-${var.asg_metrics_identifier[count.index]}-autoscaling"
    policy_type = "TargetTrackingScaling"
    resource_id = aws_appautoscaling_target.target.resource_id
    scalable_dimension = aws_appautoscaling_target.target.scalable_dimension
    service_namespace = aws_appautoscaling_target.target.service_namespace

    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = var.asg_api_metrics_monitoring[count.index]
        }

        target_value = var.asg_api_metrics_monitoring_threshold[count.index]
    }
}