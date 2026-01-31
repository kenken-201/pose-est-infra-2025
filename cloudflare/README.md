# Cloudflare Infrastructure

Cloudflare インフラストラクチャ (エッジ層 / ストレージ層) のための Terraform 設定です。

> 📖 **システム全体の概要は [pose-est-infra/README.md](../README.md) を参照してください。**

## ドキュメント

| ドキュメント                                             | 説明                            |
| -------------------------------------------------------- | ------------------------------- |
| [guidelines.md](./guidelines.md)                         | アーキテクチャ詳細・設計思想    |
| [todo-list.md](./todo-list.md)                           | 開発タスクの進捗状況            |
| [docs/setup-auth.md](./docs/setup-auth.md)               | Cloudflare 認証セットアップ手順 |
| [docs/alert_setup_guide.md](./docs/alert_setup_guide.md) | アラート設定ガイド              |

## クイックスタート

```bash
# 認証情報の確認
./scripts/verify-auth.sh

# 開発環境への適用
./scripts/plan-dev.sh
./scripts/apply-dev.sh
```
