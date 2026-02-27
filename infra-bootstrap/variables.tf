variable "location" {
  type    = string
  default = "eastus"
}

variable "state_rg_name" {
  type    = string
  default = "rg-msk-tfstate"
}

variable "state_storage_account_name" {
  type    = string
  default = "stmsktfstate"
}

variable "state_container_name" {
  type    = string
  default = "tfstate"
}