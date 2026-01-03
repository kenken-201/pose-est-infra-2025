# R2 環境設定ガイド

Cloud Run (バックエンド) から Cloudflare R2 に接続するために必要な環境変数の仕様と設定方法です。
これらの値はフェーズ 5 で Cloud Run の環境変数として設定します。

## 環境変数一覧

| 変数名               | 説明                         | 例 (Dev)                                        | 備考                                         |
| :------------------- | :--------------------------- | :---------------------------------------------- | :------------------------------------------- |
| `R2_ACCOUNT_ID`      | Cloudflare アカウント ID     | `1234567890abcdef...`                           | R2 ダッシュボード右側で確認可能              |
| `R2_BUCKET_NAME`     | R2 バケット名                | `pose-est-media-dev`                            | 環境ごとに異なる                             |
| `R2_ENDPOINT_URL`    | S3 互換エンドポイント        | `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` | `R2_ACCOUNT_ID` から構築可能だが明示指定推奨 |
| `R2_SIGN_EXPIRATION` | 署名付き URL の有効期限 (秒) | `3600`                                          | デフォルト 1 時間                            |

## バケット命名規則

- **Dev 環境**: `pose-est-media-dev`
- **本番環境**: `pose-est-media-prod`

※ バケットは Cloudflare 側で作成済みであることを前提とします。

## クレデンシャル

アクセスキーとシークレットキーは、Secret Manager から **ボリュームマウント** または **環境変数** として注入されます（アプリケーションの実装に依存）。

- `AWS_ACCESS_KEY_ID`: Secret Manager `r2-access-key-id-{env}`
- `AWS_SECRET_ACCESS_KEY`: Secret Manager `r2-secret-access-key-{env}`
