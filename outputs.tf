output "var_resource_ids" {
  value = module.resource_group.resource_group_id
}

output "password" {
  value     = random_password.wfj_password.result
  sensitive = true
}