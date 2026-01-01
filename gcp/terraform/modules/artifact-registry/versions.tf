terraform {
  required_version = ">= 1.14.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.24.0" # cleanup_policies
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.24.0"
    }
  }
}
