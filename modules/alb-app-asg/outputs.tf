output "alb_security_group_id" {
    value = aws_security_group.alb_security_group.id
}

output "load_balancer_target_group_arn" {
    value = aws_lb_target_group.target_group.arn
}