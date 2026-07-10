
output "use_case" {
  value = var.use_case
}

output "session_host_join_type" {
  value = local.session_host_join_type
}

output "fslogix_enabled" {
  value = local.enable_fslogix
}

output "storage_identity_type" {
  value = local.storage_identity_type
}

output "fslogix_config_method" {
  value = local.fslogix_config_method
}

output "resource_group_name" {
  value = local.rg_name
}

output "subnet_details_e" {
  value = try(module.create-vNet[0].subnet_details, null)
}

output "storage_account_name" {
  value = local.avd_storage_account_name
}

output "hostpool_name" {
  value = module.create-hostpool.hostpool_name_I
}

output "workspace_name" {
  value = module.create-workspace.WorkspaceName_I
}

output "session_host_details" {
  value = module.create-SessionHost.SessionHostVMs_Details_I
}
