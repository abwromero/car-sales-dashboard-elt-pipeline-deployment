output "ecs_security_group_id" {
    value = aws_security_group.ecs_security_group.id
}

output "ecs_app_name" {
    value = var.ecs_app_name
}

output "ecs_task_role_name" {
    value = aws_iam_role.ecs_task_role.name
}

output "ecs_task_security_group_id" {
    value = aws_security_group.ecs_security_group.id
}