# GCP Infrastructure

Infrastructure as Code (IaC) for Pose Estimation App Backend on Google Cloud Platform.

## Directory Structure

```
pose-est-infra/gcp/
├── terraform/          # Terraform configurations
│   ├── modules/        # Reusable Terraform modules
│   ├── environments/   # Environment-specific configurations
│   ├── backend.tf      # R2 Backend configuration
│   └── versions.tf     # Provider versions
├── docs/               # Documentation
└── scripts/            # Helper scripts
```

## Prerequisites

- Terraform >= 1.14.3
- GCP Account with `kenken-pose-est` project
- Cloudflare R2 credentials (for tfstate storage)

## Setup & Configuration

1. **Environment Variables**

   Copy `.env.example` to `.env` and fill in the required values:

   ```bash
   cp .env.example .env
   ```

   Required variables:

   - `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare Account ID
   - `R2_ACCESS_KEY_ID`: R2 Acess Key ID (for backend)
   - `R2_SECRET_ACCESS_KEY`: R2 Secret Access Key (for backend)
   - `GCP_PROJECT_ID`: `kenken-pose-est`

2. **Terraform Initialization**

   Initialize Terraform with the R2 backend configuration using the provided script (or manually):

   ```bash
   # Using script (Recommended)
   ./scripts/init-backend.sh

   # Or manually
   cd terraform
   terraform init \
     -backend-config="access_key=$R2_ACCESS_KEY_ID" \
     -backend-config="secret_key=$R2_SECRET_ACCESS_KEY" \
     -backend-config="endpoint=https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"
   ```

## Getting Started

See `docs/deployment-guide.md` (to be created) for details.

## Terraform State

The Terraform state is stored in Cloudflare R2 bucket `pose-est-terraform-state` with key `gcp/terraform.tfstate`.
