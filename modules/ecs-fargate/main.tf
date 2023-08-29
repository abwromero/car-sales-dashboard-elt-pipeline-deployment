# REFERENCE:
# - Create an AWS ECS Cluster Using Terraform by Tacio Nery
#   Link: https://dev.to/thnery/create-an-aws-ecs-cluster-using-terraform-g80

module "alb-asg" {
    source = "../alb-app-asg"
    vpc_id = var.vpc_id
    target_app_name = var.ecs_app_name
    public_subnet_ids = var.public_subnet_ids
    health_check_path = var.health_check_path
    private_subnet_ids = var.private_subnet_ids
    alb_target_group_port = var.alb_target_group_port
    alb_listener_port = var.alb_listener_port
    alb_listener_protocol = var.alb_listener_protocol
    asg_scaling_target = "${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.aws_ecs.name}"
    asg_scalable_dimension = "ecs:service:DesiredCount"
    asg_service_namespace = "ecs"
    asg_metrics_identifier = ["memory", "cpu"]
    asg_api_metrics_monitoring = ["ECSServiceAverageMemoryUtilization", "ECSServiceAverageCPUUtilization"]
    asg_api_metrics_monitoring_threshold = [80, 80]
}

resource "aws_iam_role" "ecs_task_role" {
    name = "${var.ecs_app_name}-iam-task-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_trust_policy.json
    tags = {
        Name = "${var.ecs_app_name}-iam-task-role"
    }
}

data "aws_iam_policy_document" "ecs_trust_policy" {
    statement {
      actions = ["sts:AssumeRole"]

      principals {
        type = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
      }
    }
}

resource "aws_iam_role_policy_attachment" "ecs_permissions_policy" {
    role = aws_iam_role.ecs_task_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name = "${var.ecs_app_name}_cluster"
    tags = {
      Name = "${var.ecs_app_name}-ecs"
    }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
    name = "${var.ecs_app_name}-logs"
    tags = {
        Application = var.ecs_app_name
    }
}

resource "aws_ecs_task_definition" "ecs_task" {
    family = "${var.ecs_app_name}-task"

    container_definitions = jsonencode([
        {
            "name" : "${var.ecs_app_name}-container",
            "image" : var.docker_image,
            "entryPoint" : [],
            "environment" : var.container_environment,
            "essential" : true,
            "mountPoints": [
                {
                    "readOnly" : false,
                    "containerPath" : var.mount_point_container_path,
                    "sourceVolume" : "${var.ecs_app_name}-efs-storage"
                }
            ]
            "logConfiguration" : {
                "logDriver" : "awslogs",
                "options" : {
                    "awslogs-group" : "${aws_cloudwatch_log_group.ecs_log_group.id}",
                    "awslogs-region" : "us-east-1",
                    "awslogs-stream-prefix" : "${var.ecs_app_name}" 
                }
            },
            "portMappings" : [
                {
                    "containerPort": var.container_port,
                    "hostPort" : var.host_port
                }
            ],
            "cpu" : var.ecs_container_cpu_size,
            "memory" : var.ecs_container_memory_size,
            "networkMode" : "awsvpc"
        }
    ])
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    memory = var.ecs_task_memory_size
    cpu = var.ecs_task_cpu_size
    execution_role_arn = aws_iam_role.ecs_task_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn

    tags = {
        Name = "${var.ecs_app_name}-task-definition"
    }

    volume {
        name = "${var.ecs_app_name}-efs-storage"

        efs_volume_configuration {
            file_system_id = var.ecs_efs_vol_id
            transit_encryption = "ENABLED"
            authorization_config {
              access_point_id = var.ecs_efs_access_point_id
            }
        }
    }
}

data "aws_ecs_task_definition" "ecs_task_definition" {
    task_definition = aws_ecs_task_definition.ecs_task.family
}

resource "aws_ecs_service" "aws_ecs" {
    name = "${var.ecs_app_name}-ecs-service"
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = "${aws_ecs_task_definition.ecs_task.family}:${max(aws_ecs_task_definition.ecs_task.revision, data.aws_ecs_task_definition.ecs_task_definition.revision)}"
    launch_type = "FARGATE"
    scheduling_strategy = "REPLICA"
    desired_count = 1
    force_new_deployment = true

    network_configuration {
        subnets = var.private_subnet_ids
        assign_public_ip = false
        security_groups = [
            aws_security_group.ecs_security_group.id,
            module.alb-asg.alb_security_group_id
        ]
    }

    load_balancer {
        target_group_arn = module.alb-asg.load_balancer_target_group_arn
        container_name = "${var.ecs_app_name}-container"
        container_port = var.container_port
    }

    depends_on = [module.alb-asg.aws_lb_listener]
}

resource "aws_security_group" "ecs_security_group" {
    vpc_id = var.vpc_id

    ingress {
        from_port = var.host_port
        to_port = var.host_port
        protocol = "tcp"
        security_groups = [module.alb-asg.alb_security_group_id]
    }

    ingress {
        from_port   = 2049
        to_port     = 2049
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr_block]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = false
        cidr_blocks = [var.vpc_cidr_block]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "${var.ecs_app_name}-service-security_group"
    }
}