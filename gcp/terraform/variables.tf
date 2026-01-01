variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region to deploy resources to"
  type        = string
  default     = "asia-northeast1"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, production)"
  type        = string
  default     = "dev"
}
