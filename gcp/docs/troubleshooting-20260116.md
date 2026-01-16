# トラブルシューティングレポート (2026-01-16)

## 概要

Cloud Run 上のバックエンドサービス (`kenken-pose-est`) から Cloudflare R2 ストレージへのアクセス時に認証エラーが発生しました。

## エラー詳細

- **エラー種別**: `botocore.exceptions.ClientError: An error occurred (Unauthorized)`
- **発生箇所**: `PutObject` オペレーション（ファイル書き込み時）
- **対象バケット**: `pose-est-videos-prod`

## 調査事項 (Infrastructure)

### Cloud Run 設定

1. **環境変数**:
   - `R2_ACCESS_KEY_ID`: 正しいアクセスキー ID が設定されているか？
   - `R2_SECRET_ACCESS_KEY`: シークレットマネージャー等から正しいキーが注入されているか？
   - `R2_BUCKET_NAME`: `pose-est-videos-prod` が設定されているが、開発環境 (`dev`) の設定として適切か確認が必要。

### 推奨アクション

- Terraform の `gcp/cloud_run` モジュール定義、および `tfvars` を確認し、開発環境用のバケット設定 (`pose-est-videos-dev`) が適用されるべきではないか検討する。
- シークレット (`R2_SECRET_ACCESS_KEY`) の値が Cloudflare 側で発行されたものと一致しているか確認する。
