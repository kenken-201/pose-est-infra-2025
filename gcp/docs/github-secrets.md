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

## セキュリティに関する詳細とベストプラクティス

### 1. Workload Identity Federation (WIF)

- **キーレス認証**: 従来の長期間有効なサービスアカウントキー（JSON）を使用せず、一時的なトークンを使用するため、漏洩リスクが大幅に低減されます。
- **属性条件**: Workload Identity Pool Provider の設定で `attribute.repository_owner` 等の条件を設定することで、特定のリポジトリからのリクエストのみを許可しています（推奨）。

### 2. GitHub Actions のバージョン固定

本番環境のワークフローでは、サプライチェーン攻撃を防ぐため、Action のバージョンを SHA ハッシュで固定することを強く推奨します。

```yaml
# 推奨設定例（バージョンは適宜最新を確認してください）
uses: google-github-actions/auth@6fc4af4b145ae7821d527454aa9bd537d1f2dc5f # v2
uses: hashicorp/setup-terraform@a1502cd9e758c50496cc9ac5308c48ae4db1d30d # v3
```

### 3. Secrets の安全性

- GitHub Secrets は暗号化されて保存されます。
- ログ出力時は自動的にマスク（`***`）されますが、デバッグ出力などで誤って値を表示しないよう注意してください。
- Terraform のバックエンド設定（`terraform init`）で Secret を使用する際も、コマンドライン引数として渡すことで、コード内にハードコーディングすることを防いでいます。
