terraform {
  backend "azurerm" {
    storage_account_name = "trenstorage"
    container_name       = "tfback"
    key                  = "prod.terraform.tfstate" # Name given to the tfstate file

    # rather than defining this inline, the Access Key can also be sourced
    # from an Environment Variable - more information is available below.
    access_key = "n5P8jVaMYN6Djt38rODmT5MTX6L5IWbgnQxaIBjEZ+nXOgp+Phb5GmFCK73wdKCMf4aI+R5boquh+AStsT7kyg=="
  }
}
