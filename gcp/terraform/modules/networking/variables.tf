variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, production)"
  type        = string

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "Environment must be either 'dev' or 'production'."
  }
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "The subnet_cidr must be a valid CIDR block."
  }
}
