variable "brand" {
  type    = string
  default = "msk"
}

variable "org" {
  type = string
}

variable "env" {
  type = string
  description = "Environment name: dev|stage|prod"
  default     = "dev"
}

variable "location" {
  type = string
  description = "Azure region"
  default     = "centralus"
}

variable "enable_replay" {
  type        = bool
  description = "Create replay consumer group + replay container"
  default     = true
}

variable "eventhub_partitions" {
  type        = number
  description = "Event Hub partitions (changing later is painful)"
  default     = 4
}

variable "eventhub_retention_days" {
  type        = number
  description = "Event Hub retention days"
  default     = 2
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "head_container_image" {
  type        = string
  description = "Container image for Head Puller host"
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "enable_dab" {
  type        = bool
  description = "Enable Data API Builder container app"
  default     = true
}

variable "dab_container_image" {
  type        = string
  description = "Container image for Data API Builder host"
  default     = "mcr.microsoft.com/azure-databases/data-api-builder:latest"
}
