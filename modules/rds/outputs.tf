output "rds_hostname" {
  value = aws_db_instance.db_deployment.address
}

output "rds_endpoint" {
  value = aws_db_instance.db_deployment.endpoint
}

output "rds_username" {
  value     = module.rds_secrets.username
  sensitive = true
}

output "rds_password" {
  value     = module.rds_secrets.password
  sensitive = true
}

output "rds_secret_version_id" {
  value = module.rds_secrets.id
}

output "rds_db_name" {
  value = aws_db_instance.db_deployment.name
}