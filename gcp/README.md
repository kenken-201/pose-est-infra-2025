# GCP Infrastructure

Google Cloud Platform インフラストラクチャ (バックエンド API / Cloud Run) のための Terraform 設定です。

> 📖 **システム全体の概要は [pose-est-infra/README.md](../README.md) を参照してください。**

## ドキュメント

| ドキュメント                                                   | 説明                         |
| -------------------------------------------------------------- | ---------------------------- |
| [guidelines.md](./guidelines.md)                               | アーキテクチャ詳細・設計思想 |
| [todo-list.md](./todo-list.md)                                 | 開発タスクの進捗状況         |
| [docs/cloud-run-deployment.md](./docs/cloud-run-deployment.md) | Cloud Run デプロイ手順       |
| [docs/troubleshooting-gcp.md](./docs/troubleshooting-gcp.md)   | トラブルシューティング       |
| [docs/github-secrets.md](./docs/github-secrets.md)             | GitHub Secrets 設定          |
| [docs/security-checklist.md](./docs/security-checklist.md)     | セキュリティチェックリスト   |

## クイックスタート

```bash
# 認証情報の確認
./scripts/verify-auth.sh

# 開発環境への適用
./scripts/plan-dev.sh
./scripts/apply-dev.sh
```
