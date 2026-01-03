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
SERVICE_URL=$(terraform output -raw service_url)
curl "${SERVICE_URL}/health"
```

**期待される応答**:

```json
{ "status": "ok" }
```

(または FastAPI の定義に準じた 200 OK レスポンス)

## 5. ログと監視の確認

デプロイ後、アプリケーションが正しく動作しているか GCP コンソールまたは CLI で確認します。

### 5.1 Cloud Logging (ログ確認)

以下のコマンドで最新のアプリケーションログを確認できます。

```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=pose-est-backend-dev" --limit 20
```

### 5.2 Cloud Monitoring (メトリクス確認)

GCP コンソールの Cloud Run 画面 > 「モニタリング」タブで以下を確認します。
- リクエスト数 (Requests)
- インスタンス数 (Active Instances)
- メモリ/CPU 使用率 (Utilization)

## 6. 次のステップ (Cloudflare 連携)

この URL を使用して、Cloudflare 側で CNAME レコード ("api") を作成します。
(詳細は Cloudflare インフラ側のドキュメントを参照)

---

## トラブルシューティング

### イメージが見つからない (ImageNotFound)

```
Error: oci runtime error: image not found
```

**原因**: Artifact Registry にコンテナイメージがプッシュされていない。

**対応**:

1. GitHub Actions (`docker-build-push.yml`) を実行してイメージをプッシュ。
2. または、手動でプッシュ:
   ```bash
   docker tag pose-est-backend:latest asia-northeast1-docker.pkg.dev/kenken-pose-est/pose-est-backend-dev/pose-est-backend:latest
   docker push asia-northeast1-docker.pkg.dev/kenken-pose-est/pose-est-backend-dev/pose-est-backend:latest
   ```

### シークレットが見つからない (SecretVersionAccessDenied)

```
Error: Secret version not found or access denied
```

**原因**: Secret Manager にシークレット値が登録されていないか、バージョンが存在しない。

**対応**:

1. `scripts/register-r2-secrets.sh` を実行してシークレット値を登録。
2. Secret Manager コンソールでバージョンが存在するか確認。

### ヘルスチェック失敗 (HealthCheckFailed)

**原因**: アプリケーションが `/health` エンドポイントで 200 を返していない。

**対応**:

1. ローカルで Docker イメージを起動し、`curl localhost:8080/health` でレスポンスを確認。
2. FastAPI アプリケーションのルート定義を確認。
