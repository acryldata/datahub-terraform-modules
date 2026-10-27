output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "frontend_sg_id" {
  value = aws_security_group.frontend.id
}

output "gms_sg_id" {
  value = aws_security_group.gms.id
}

output "actions_sg_id" {
  value = aws_security_group.actions.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "msk_sg_id" {
  value = aws_security_group.msk.id
}

output "opensearch_sg_id" {
  value = aws_security_group.opensearch.id
}

output "system_update_sg_id" {
  value = aws_security_group.system_update.id
}
