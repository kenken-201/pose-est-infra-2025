# GCP Infrastructure

Infrastructure as Code (IaC) for Pose Estimation App Backend on Google Cloud Platform.

## Directory Structure

- `terraform/`: Terraform configurations
  - `modules/`: Reusable Terraform modules
  - `environments/`: Environment-specific configurations
- `docs/`: Documentation
- `scripts/`: Helper scripts

## Prerequisites

- Terraform >= 1.14.3
- GCP Account with `kenken-pose-est` project
- Cloudflare R2 credentials (for tfstate storage)

## Getting Started

See `docs/deployment-guide.md` (to be created) for details.

## Terraform State

The Terraform state is stored in Cloudflare R2 bucket `pose-est-terraform-state` with key `gcp/terraform.tfstate`.
