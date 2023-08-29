terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

resource "random_pet" "efs_token_name" {
  length    = 1
  prefix    = "efs_vol_"
  separator = ""
}

resource "aws_efs_file_system" "efs_vol" {
  creation_token   = random_pet.efs_token_name.id
  encrypted        = true
  performance_mode = "generalPurpose"

  tags = {
    "Name" = "${var.efs_app_name}-EFS"
  }
}

data "aws_iam_policy_document" "efs_policy" {
  statement {
    sid    = "efs_iam_policy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]

    resources = [aws_efs_file_system.efs_vol.arn]
  }
}

resource "aws_efs_file_system_policy" "efs_attached_policy" {
  file_system_id = aws_efs_file_system.efs_vol.id
  policy         = data.aws_iam_policy_document.efs_policy.json
}

resource "aws_security_group" "tf_efs_sg" {
  name        = "${var.efs_app_name}_efs"
  description = "Security Group for the EFS cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [var.service_security_group]
  }

  tags = {
    Name = "${var.efs_app_name}_EFS_SG"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  count           = 2
  file_system_id  = aws_efs_file_system.efs_vol.id
  subnet_id       = var.efs_subnet_ids[count.index]
  security_groups = [aws_security_group.tf_efs_sg.id]
}

resource "aws_efs_access_point" "efs_access_point" {
  file_system_id = aws_efs_file_system.efs_vol.id
  root_directory {
    creation_info {
      owner_gid = "0"
      owner_uid = "0"
      permissions = "0777"
    }
    path = var.efs_access_point_root_path
  }
  posix_user {
    gid = "0"
    uid = "0"
  }
}