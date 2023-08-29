output "efs_id" {
  value = aws_efs_file_system.efs_vol.id
}

output "efs_mounts_ip" {
  value = aws_efs_mount_target.efs_mount_target[*].ip_address
}

output "efs_access_point_id" {
  value = aws_efs_access_point.efs_access_point.id
}