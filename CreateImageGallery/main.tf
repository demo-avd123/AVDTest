

# generate a random string (consisting of four characters)
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "random" {
  length  = 4
  upper   = false
  special = false
}


# Creates Shared Image Gallery
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image_gallery
resource "azurerm_shared_image_gallery" "sig" {
  name                = "sig${random_string.random.id}"
  resource_group_name = var.rg_name_I
  location            = var.location_I
  description         = "Shared images"

  tags = {
    Environment = var.env_I
  }
}
//not using below code for now for image definition and image version creation
# # # #Creates image definition
# # # # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image
# # # resource "azurerm_shared_image" "example" {
# # #   name                = "avd-image"
# # #   gallery_name        = azurerm_shared_image_gallery.sig.name
# # #   resource_group_name = "uks-factory-poc"
# # #   location            = "uksouth"
# # #   os_type             = "Windows"

# # #   identifier {
# # #     publisher = "MicrosoftWindowsDesktop"
# # #     offer     = "office-365"
# # #     sku       = "20h2-evd-o365pp"
# # #   }
# # # }
