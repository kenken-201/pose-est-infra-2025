# セキュリティチェックリスト (Cloud Run 公開前)

バックエンドアプリケーション (`pose-est-backend-dev`) を公開する前に確認すべき項目のリストです。

## 1. IAM / アクセス制御

- [ ] **最小権限**: サービスアカウント `cloud-run-sa` は必要なリソース (Artifact Registry, Secret Manager, Cloud Logging) **のみ** へのアクセス権を持っているか？
  - [x] Artifact Registry: `roles/artifactregistry.reader` (リソースレベル)
  - [x] Secret Manager: `roles/secretmanager.secretAccessor` (リソースレベル)
- [ ] **公開範囲**: Dev 環境の `roles/run.invoker` は `allUsers` (認証なし) になっているか？
  - ※ 本番環境では IAP や Cloudflare Access による制限を検討すること。

## 2. シークレット管理

- [ ] **環境変数**: 機密情報 (R2 クレデンシャル) が Terraform コード内にハードコードされていないか？
  - [x] `modules/cloud-run` は `value_source` を使用して Secret Manager 参照を行っている。
- [ ] **Terraform State**: State ファイルにシークレット値が含まれていないか？
  - [x] Secret Manager の値は `gcloud` で登録し、Terraform は「箱」のみ管理している。

## 3. アプリケーション設定

- [ ] **CORS**: フロントエンド (`kenken-pose-est.online`, localhost) からのアクセスのみ許可されているか？ (FastAPI 設定確認)
- [ ] **デバッグモード**: 本番環境では `DEBUG=False` になっているか？ (現在は Dev 環境なので `True` 可)

## 4. ネットワーク

- [ ] **HTTPS 強制**: Cloud Run はデフォルトで HTTPS を強制するため、特段の対応は不要。
- [ ] **不要なポート**: コンテナは 8080 ポートのみをリッスンしているか？

## 5. R2 連携

- [ ] **署名付き URL の有効期限**: 必要最小限 (例: 1 時間) に設定されているか？ (`R2_SIGN_EXPIRATION`)
- [ ] **バケットアクセス**: 古い API トークンが存在しないか？ (ローテーションポリシー準拠)
