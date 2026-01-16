# トラブルシューティングレポート (2026-01-16)

## 概要

GCP (Cloud Run) から R2 バケットへのアクセス時に `Unauthorized` エラーが発生しています。Cloudflare 側でのトークン管理に関連する可能性があります。

## 確認事項

1. **R2 API トークン**:
   - バックエンドで使用しているトークンが、`pose-est-videos-prod` (および dev) バケットに対して **Edit (Read/Write)** 権限を持っているか確認してください。
   - トークンの有効期限が切れていないか確認してください。
   - Terraform (`cloudflare/r2`) でトークンを管理している場合、権限スコープが適切か `main.tf` を確認してください。

## 関連エラー

- GCP/Backend 側で `botocore.exceptions.ClientError: An error occurred (Unauthorized) when calling the PutObject operation` が発生中。
