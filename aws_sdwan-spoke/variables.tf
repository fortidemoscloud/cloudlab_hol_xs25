# ----------------------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------------------
variable "prefix" {
  description = "Prefix to configured items in AWS"
  type        = string
  default     = "sdwan-spoke"
}

variable "custom_vars" {
  description = "Custom variables as JSON string"
  type        = string
  default     = "{}"
}

variable "spoke" {
  description = "SDWAN spoke values"
  type        = string
  default     = "{}"
}

variable "hubs" {
  description = "SDWAN HUBs values"
  type        = string
  default     = "[{}]"
}

variable "hubs_secret_id" {
  description = "SDWAN HUBs values"
  type        = string
  default     = ""
}

variable "deploy_role_arn" {
  description = "ARN of the role to assume for deployment"
  type        = string
  default     = ""
}

variable "external_id" {
  description = "External ID for assuming the deployment role"
  type        = string
  default     = ""
}

variable "session_name" {
  description = "Session name for assuming the deployment role"
  type        = string
  default     = "deploy"
}