output "created_groups" {
  description = "Created Identity Center Groups"
  value = {
    devops_group_id     = aws_identitystore_group.devops.group_id
    developers_group_id = aws_identitystore_group.developers.group_id
  }
}

output "permission_set_arns" {
  description = "Permission Set ARNs"
  value = {
    admin_arn    = aws_ssoadmin_permission_set.admin.arn
    readonly_arn = aws_ssoadmin_permission_set.readonly.arn
  }
}