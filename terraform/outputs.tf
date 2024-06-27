output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.default.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = aws_subnet.private[*].id
}

output "nfs_security_group_id" {
  description = "ID del grupo de seguridad NFS"
  value       = aws_security_group.nfs.id
}
