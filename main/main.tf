# REFERENCE:
# - DevOps Bootcamp: Terraform by Andrei Neagoie and Andrei Dumitrescu
#   Link: https://www.udemy.com/course/devops-bootcamp-terraform-certification/
# - How Can I Reference Terraform Cloud Environment Variables?
#   Link: https://stackoverflow.com/questions/66598788/terraform-how-can-i-reference-terraform-cloud-environmental-variables
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.63.0"
    }
  }
  cloud {
    organization = ""
    workspaces {
      name = ""
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../modules/vpc"
}

module "mage_efs" {
    source = "../modules/efs"
    efs_app_name = "mage"
    vpc_id = module.vpc.vpc_id
    vpc_cidr_block = module.vpc.vpc_cidr_block
    efs_subnet_ids = [
      module.vpc.private_subnets_ids[0],
      module.vpc.private_subnets_ids[1]
    ]
    service_security_group = module.mage_ecs.ecs_task_security_group_id
    efs_access_point_root_path = "/home/src"
}

resource "aws_iam_role_policy_attachment" "mage_ecs_efs_policy" {
    role = module.mage_ecs.ecs_task_role_name
    policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
}

module "mage_rds" {
    source = "../modules/rds"
    vpc_id = module.vpc.vpc_id
    rds_subnets_ids = module.vpc.private_subnets_ids
    rds_ingress_security_groups = [module.mage_ecs.ecs_security_group_id]
    microservice_name = module.mage_ecs.ecs_app_name
    vpc_cidr_block = module.vpc.vpc_cidr_block
}

resource "aws_iam_role_policy_attachment" "mage_ecs_rds_policy" {
    role = module.mage_ecs.ecs_task_role_name
    policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

module "mage_ecs" {
  source = "../modules/ecs-fargate"
  ecs_app_name = "mage"
  docker_image = "mageai/mageai:0.9.0"
  ecs_container_cpu_size = 1024
  ecs_container_memory_size = 2048
  ecs_task_cpu_size = "2048"
  ecs_task_memory_size = "4096"
  ecs_efs_vol_id = module.mage_efs.efs_id
  ecs_efs_access_point_id = module.mage_efs.efs_access_point_id
  vpc_id = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
  public_subnet_ids = module.vpc.public_subnets_ids
  mount_point_container_path = "/home/src"
  health_check_path = "/api/kernels"
  private_subnet_ids = module.vpc.private_subnets_ids
  alb_target_group_port = 6789
  alb_listener_port = "80"
  alb_listener_protocol = "HTTP"
  container_environment = [
    {
      "name" : "MAGE_DATABASE_CONNECTION_URL"
      "value" : "postgresql+psycopg2://${module.mage_rds.rds_username}:${module.mage_rds.rds_password}@${module.mage_rds.rds_hostname}:5432/${module.mage_rds.rds_db_name}"
    }
  ]
  container_port = 6789
  host_port = 6789
}

module "metabase_efs" {
    source = "../modules/efs"
    efs_app_name = "metabase"
    vpc_id = module.vpc.vpc_id
    vpc_cidr_block = module.vpc.vpc_cidr_block
    efs_subnet_ids = [
      module.vpc.private_subnets_ids[0],
      module.vpc.private_subnets_ids[1]
    ]
    service_security_group = module.metabase_ecs.ecs_task_security_group_id
    efs_access_point_root_path = "/home/node"
}

resource "aws_iam_role_policy_attachment" "metabase_ecs_efs_policy" {
    role = module.metabase_ecs.ecs_task_role_name
    policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
}

module "metabase_rds" {
    source = "../modules/rds"
    vpc_id = module.vpc.vpc_id
    vpc_cidr_block = module.vpc.vpc_cidr_block
    rds_subnets_ids = module.vpc.private_subnets_ids
    rds_ingress_security_groups = [module.metabase_ecs.ecs_security_group_id]
    microservice_name = module.metabase_ecs.ecs_app_name
}

resource "aws_iam_role_policy_attachment" "metabase_ecs_rds_policy" {
    role = module.metabase_ecs.ecs_task_role_name
    policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

module "metabase_ecs" {
  source = "../modules/ecs-fargate"
  ecs_app_name = "metabase"
  docker_image = "metabase/metabase:v0.44.7.3"
  ecs_container_cpu_size = 1024
  ecs_container_memory_size = 2048
  ecs_task_cpu_size = "2048"
  ecs_task_memory_size = "4096"
  ecs_efs_vol_id = module.metabase_efs.efs_id
  ecs_efs_access_point_id = module.metabase_efs.efs_access_point_id
  vpc_id = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
  public_subnet_ids = module.vpc.public_subnets_ids
  mount_point_container_path = "/home/node"
  health_check_path = "/api/health"
  private_subnet_ids = module.vpc.private_subnets_ids
  alb_target_group_port = 80
  alb_listener_port = "80"
  alb_listener_protocol = "HTTP"
  container_environment = [
                {
                    "name" : "MB_DB_DBNAME",
                    "value" : module.metabase_rds.rds_db_name
                },
                {
                    "name" : "MB_DB_HOST",
                    "value" : module.metabase_rds.rds_hostname
                },
                {
                    "name" : "MB_DB_USER",
                    "value" : module.metabase_rds.rds_username
                },
                {
                    "name" : "MB_DB_PASS",
                    "value" : module.metabase_rds.rds_password
                },
                {
                    "name" : "MB_DB_TYPE",
                    "value" : "postgres"
                },
                {
                    "name" : "MB_DB_PORT",
                    "value" : "5432"
                }
            ]
  container_port = 3000
  host_port = 3000
}

module "main_rds" {
    source = "../modules/rds"
    vpc_id = module.vpc.vpc_id
    rds_subnets_ids = module.vpc.private_subnets_ids
    rds_ingress_security_groups = [
      module.mage_ecs.ecs_security_group_id,
      module.metabase_ecs.ecs_security_group_id
      ]
    microservice_name = "car_sales_main_internal_database"
    vpc_cidr_block = module.vpc.vpc_cidr_block
}