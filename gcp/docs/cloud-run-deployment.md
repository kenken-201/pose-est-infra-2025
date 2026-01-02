# Cloud Run デプロイ & 確認手順 (Dev 環境)

このドキュメントでは、Terraform を使用して Cloud Run サービスをデプロイし、稼働確認を行うまでの手順を説明します。

## 1. 前提条件

- [x] `terraform plan` がエラーなく通ること (`scripts/check-quality.sh` 確認済み)
- [ ] Artifact Registry にコンテナイメージがプッシュされていること
  - まだの場合は GitHub Actions を実行するか、手動でプッシュしてください。
  - イメージ URL: `asia-northeast1-docker.pkg.dev/kenken-pose-est/pose-est-backend-dev/pose-est-backend:latest`

## 2. Terraform Apply

バックエンドディレクトリで以下を実行します。

```bash
cd environments/dev
# R2 アカウント ID を環境変数として渡す
export TF_VAR_r2_account_id="<YOUR_CLOUDFLARE_ACCOUNT_ID>"

# 適用
terraform apply
```

確認プロンプトが表示されたら `yes` と入力します。

## 3. URL の取得

成功すると、`outputs` に Cloud Run の URL が表示されます。

```
module.cloud_run.service_url = "https://pose-est-backend-dev-xxxxxxxx.a.run.app"
```

## 4. 動作確認 (Health Check)

取得した URL に `/health` エンドポイントを付けてアクセスします。

```bash
SERVICE_URL=$(terraform output -raw service_url) # module階層によってはパス調整が必要
curl "${SERVICE_URL}/health"
```

**期待される応答**:

```json
{ "status": "ok" }
```

(または FastAPI の定義に準じた 200 OK レスポンス)

## 5. 次のステップ (Cloudflare 連携)

この URL を使用して、Cloudflare 側で CNAME レコード ("api") を作成します。
(詳細は Cloudflare インフラ側のドキュメントを参照)
