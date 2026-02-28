variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-msk-tfstate"
}

variable "storage_account_name" {
  type    = string
  default = "stmsktfstate"
}

variable "container_name" {
  type    = string
  default = "tfstate"
}