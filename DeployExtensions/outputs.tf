output "extensions_deployed" {
  value = {
    join_type       = var.session_host_join_type_I
    fslogix_enabled = var.enable_fslogix_I
    fslogix_method  = var.fslogix_config_method_I
  }
}
