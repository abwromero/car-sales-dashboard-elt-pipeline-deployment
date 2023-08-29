output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main_vpc.cidr_block
}

output "private_subnets_ids" {
  value = aws_subnet.private.*.id
}

output "public_subnets_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnets_cidr_blocks" {
  value = [aws_subnet.private[0].cidr_block, aws_subnet.private[1].cidr_block]
}

output "route_table_public_id" {
  value = aws_route_table.public.id
}

output "route_table_private_id" {
  value = [aws_route_table.private[0].id, aws_route_table.private[1].id]
}

output "azs" {
  value = aws_subnet.public[*].availability_zone
}