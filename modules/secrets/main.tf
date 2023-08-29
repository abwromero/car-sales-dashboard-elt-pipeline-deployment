terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

resource "random_pet" "username" {
  length    = 2
  prefix    = "random"
  separator = ""
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "._-"
}

resource "random_id" "secret_name" {
  byte_length = 2
  prefix      = "randomid"
}

resource "aws_secretsmanager_secret" "login_values" {
  name = random_id.secret_name.id
}

resource "aws_secretsmanager_secret_version" "login_secret_version" {
  secret_id = aws_secretsmanager_secret.login_values.id
  secret_string = jsonencode({
    username = random_pet.username.id
    password = random_password.password.result
  })
}

locals {
  db_login = jsondecode(aws_secretsmanager_secret_version.login_secret_version.secret_string)
}