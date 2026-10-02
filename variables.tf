variable "subscription_id" {
  type        = string
  description = "Target sandbox subscription UUID; not a credential."
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Use a subscription UUID."
  }
}
variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant UUID."
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Use a tenant UUID."
  }
}
variable "suffix" {
  type        = string
  description = "Globally unique lowercase alphanumeric suffix, 6-12 characters."
  validation {
    condition     = can(regex("^[a-z0-9]{6,12}$", var.suffix))
    error_message = "suffix must contain 6-12 lowercase letters or digits."
  }
}
variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region; confirm availability and pricing before deployment."
}
