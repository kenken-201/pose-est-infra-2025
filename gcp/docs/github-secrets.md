# GitHub Secrets 設定ガイド

本ドキュメントでは、GitHub Actions から GCP リソースにアクセスするために必要な Secrets の設定手順を説明します。

## 必要な Secrets 一覧

| Secret 名                        | 値                                                                                                           | 説明                           |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------ |
| `GCP_PROJECT_ID`                 | `kenken-pose-est`                                                                                            | GCP プロジェクト ID            |
| `GCP_REGION`                     | `asia-northeast1`                                                                                            | GCP リージョン                 |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/776417398860/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider` | Workload Identity Provider     |
| `GCP_SERVICE_ACCOUNT`            | `terraform-admin@kenken-pose-est.iam.gserviceaccount.com`                                                    | Terraform 用サービスアカウント |
| `R2_ACCESS_KEY_ID`               | (値は Cloudflare ダッシュボードから取得)                                                                     | Cloudflare R2 アクセスキー     |
| `R2_SECRET_ACCESS_KEY`           | (値は Cloudflare ダッシュボードから取得)                                                                     | Cloudflare R2 シークレット     |
| `CLOUDFLARE_ACCOUNT_ID`          | (値は Cloudflare ダッシュボードから取得)                                                                     | Cloudflare アカウント ID       |

## 設定手順

1. GitHub リポジトリの **Settings > Secrets and variables > Actions** にアクセス
2. **New repository secret** をクリック
3. 上記の各 Secret を追加

## GitHub Actions での使用例

```yaml
jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write # Workload Identity Federation に必要

    steps:
      - uses: actions/checkout@v4

      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: |
          cd pose-est-infra/gcp/terraform
          terraform init \
            -backend-config="access_key=${{ secrets.R2_ACCESS_KEY_ID }}" \
            -backend-config="secret_key=${{ secrets.R2_SECRET_ACCESS_KEY }}" \
            -backend-config="endpoint=https://${{ secrets.CLOUDFLARE_ACCOUNT_ID }}.r2.cloudflarestorage.com"
```

## セキュリティに関する注意

- **Workload Identity Federation** を使用しているため、サービスアカウントキー（JSON）は不要です
- Secrets は暗号化されて保存され、ログには表示されません
- `id-token: write` パーミッションが必要です
