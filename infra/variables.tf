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
