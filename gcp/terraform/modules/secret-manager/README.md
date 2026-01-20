# Secret Manager Terraform Module

Cloudflare R2 のクレデンシャルを管理するための Secret Manager リソースを作成するモジュールです。

## 概要

セキュリティのベストプラクティスに従い、Terraform では **シークレットの「箱」（リソース定義）** のみを作成します。
**シークレットの「値」（実際のキー）** は Terraform State に保存されるリスクを避けるため、`gcloud` CLI やコンソールから手動で登録する運用とします。

## リソース

- **Secrets**:
  - `r2-access-key-id-${var.environment}`
  - `r2-secret-access-key-${var.environment}`
- **IAM**:
  - 指定された Cloud Run サービスアカウントに対して、上記のシークレットリソースへの `roles/secretmanager.secretAccessor`（ペイロードアクセス権）を付与します。
  - プロジェクトレベルではなく、リソースレベルで権限を付与することで、最小権限の原則（Least Privilege）を遵守しています。

## 初期セットアップ手順

モジュール適用後、以下のコマンドで実際の値を登録してください：

```bash
# 環境変数を設定 (例)
export ENV=dev
export ACCESS_KEY_ID="<YOUR_R2_ACCESS_KEY_ID>"
export SECRET_ACCESS_KEY="<YOUR_R2_SECRET_ACCESS_KEY>"

# Access Key ID 登録
echo -n "$ACCESS_KEY_ID" | gcloud secrets versions add r2-access-key-id-$ENV --data-file=-

# Secret Access Key 登録
echo -n "$SECRET_ACCESS_KEY" | gcloud secrets versions add r2-secret-access-key-$ENV --data-file=-
```

## Inputs

| Name                  | Description                                        | Type     | Required |
| --------------------- | -------------------------------------------------- | -------- | :------: |
| `project_id`          | GCP Project ID                                     | `string` |   yes    |
| `environment`         | Environment name (dev, production)                 | `string` |   yes    |
| `cloud_run_sa_member` | IAM member for Cloud Run SA (`serviceAccount:...`) | `string` |   yes    |
