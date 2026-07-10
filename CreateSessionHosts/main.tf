

# ===================================================================
# DATA SOURCE: Custom image version from Azure Compute Gallery
# Only fetched when use_custom_image_I = true
# ===================================================================
data "azurerm_shared_image_version" "custom_image" {
  count               = var.use_custom_image_I ? 1 : 0
  name                = try(var.image_gallery_version_I, "placeholder")
  image_name          = try(var.image_definition_name_I, "placeholder")
  gallery_name        = try(var.image_gallery_name_I, "placeholder")
  resource_group_name = try(var.image_gallery_rg_I, "placeholder")
}

# NICs for VMs
resource "azurerm_network_interface" "session_host_nic" {
  name                = var.folllowNomenclature_I == true ? "${var.prefix_I}-${var.env_I}-${var.sessionHost_name_I}-${count.index}-nic" : "${var.sessionHost_name_I}-${count.index}-nic"
  location            = var.location_I
  resource_group_name = var.rg_name_I
  count               = var.sh_count_I

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.subnet_id_I
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.tags_I, {
    cm-resource-parent = "/subscriptions/${var.subscription_id_I}/resourceGroups/${var.rg_name_I}/providers/Microsoft.Network/networkInterfaces/${var.folllowNomenclature_I ? "${var.prefix_I}-${var.env_I}-${var.sessionHost_name_I}-${count.index}-nic" : "${var.sessionHost_name_I}-${count.index}-nic"}"
  })
}

# Session Hosts (VMs)
resource "azurerm_windows_virtual_machine" "session_host" {
  count                      = var.sh_count_I
  name                       = var.folllowNomenclature_I == true ? "${var.prefix_I}-${var.env_I}-${var.sessionHost_name_I}-${count.index}" : "${var.sessionHost_name_I}-${count.index}"
  location                   = var.location_I
  resource_group_name        = var.rg_name_I
  size                       = var.sku_I
  admin_username             = var.admin_username_I
  admin_password             = var.admin_password_I
  zone                       = var.zone_I
  encryption_at_host_enabled = var.encryption_I
  secure_boot_enabled        = var.secure_boot_I
  vtpm_enabled               = var.vtpm_I
  network_interface_ids = [
    azurerm_network_interface.session_host_nic[count.index].id
  ]
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_st_acc_type_I
  }

  # Custom gallery image takes priority when use_custom_image_I = true
  source_image_id = var.use_custom_image_I ? data.azurerm_shared_image_version.custom_image[0].id : null

  dynamic "source_image_reference" {
    for_each = var.use_custom_image_I ? [] : [1]
    content {
      publisher = var.image_publisher_I
      offer     = var.image_offer_I
      sku       = var.image_sku_I
      version   = var.image_version_I
    }
  }

  tags = merge(var.tags_I, {
    cm-resource-parent = "/subscriptions/${var.subscription_id_I}/resourceGroups/${var.rg_name_I}/providers/Microsoft.Compute/virtualMachines/${var.folllowNomenclature_I ? "${var.prefix_I}-${var.env_I}-${var.sessionHost_name_I}-${count.index}" : "${var.sessionHost_name_I}-${count.index}"}"
  })
}

# Auto-shutdown schedule (only created when auto_shutdown_enabled_I = true)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  count              = var.auto_shutdown_enabled_I ? var.sh_count_I : 0
  virtual_machine_id = azurerm_windows_virtual_machine.session_host[count.index].id
  location           = var.location_I
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time_I
  timezone              = var.auto_shutdown_timezone_I

  notification_settings {
    enabled = false
  }

  tags = merge(var.tags_I, {
    cm-resource-parent = azurerm_windows_virtual_machine.session_host[count.index].id
  })
}
