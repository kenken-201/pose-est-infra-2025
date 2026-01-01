/*
  Terraform バージョンとプロバイダー設定
  -----------------------------------------------------------------------------
  GCPリソースを管理するためのTerraformとプロバイダーのバージョンを固定します。
*/

terraform {
  required_version = ">= 1.14.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6"
    }
  }
}
