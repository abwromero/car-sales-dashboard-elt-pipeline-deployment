output "username" {
  value     = local.db_login.username
  sensitive = true
}

output "password" {
  value     = local.db_login.password
  sensitive = true
}

output "id" {
  value = aws_secretsmanager_secret_version.login_secret_version.id
}